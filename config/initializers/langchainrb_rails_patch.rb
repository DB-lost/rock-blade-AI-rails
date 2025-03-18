# frozen_string_literal: true

module LangchainrbRails
  module ActiveRecord
    module Hooks
      def upsert_to_vectorsearch
        Rails.logger.info("this is updated patch")

        # 获取 Langchain 提供的 vectorsearch provider
        provider = self.class.class_variable_get(:@@provider)

        # 如果使用了 DSL 的方式定义 payload（见下面 Post 中的 vectorsearch do ... end），
        # 可以通过 self.vectorsearch_payload(self) 获取。也可自行定义 as_payload 方法等。
        payload_data =
          if respond_to?(:vectorsearch_payload)
            vectorsearch_payload
          elsif respond_to?(:as_payload)
            as_payload
          else
            {}
          end

        # 这里可以再做一层防御或增加更多通用字段
        payload_data[:model_name] ||= self.class.name if self.class.respond_to?(:name)

        # 如果是新纪录，则调用 add_texts，否则 update_texts
        if Rails.env != "test"
          if previously_new_record?
            provider.add_texts(
              texts: [ as_vector ],    # 这里把多字段合并后的"可嵌入"文本传入
              ids: [ id ],
              payload: payload_data
            )
          else
            provider.update_texts(
              texts: [ as_vector ],
              ids: [ id ],
              payload: payload_data
            )
          end
        end
        true # 保持返回值
      end

      module ClassMethods
        # 覆盖 similarity_search，让其支持基于 user_id 的简单过滤
        def similarity_search(query, k: 3, user_id: nil, min_score: nil, return_scores: false)
          search_params = {}

          # 如果传入了 user_id，就把它加入 Qdrant 的 filter
          if user_id && LangchainrbRails.config.vectorsearch.is_a?(Langchain::Vectorsearch::Qdrant)
            filter = {
              must: [
                {
                  key: "user_id",
                  match: {
                    value: user_id
                  }
                }
              ]
            }
          end

          # 根据不同的向量搜索引擎调用不同的方法
          if LangchainrbRails.config.vectorsearch.is_a?(Langchain::Vectorsearch::Qdrant)
            # 对于 Qdrant，使用命名参数调用
            records = if filter
                        class_variable_get(:@@provider).similarity_search(
                          query: query,
                          k: k,
                          filter: filter
                        )
            else
                        class_variable_get(:@@provider).similarity_search(
                          query: query,
                          k: k
                        )
            end
          else
            # 对于其他向量搜索引擎，使用哈希参数调用
            search_params[:query] = query
            search_params[:k] = k
            search_params[:filter] = filter if filter
            records = class_variable_get(:@@provider).similarity_search(search_params)
          end

          # 应用相似度阈值过滤
          if min_score && records.first.is_a?(Hash) && records.first.key?("score")
            records = records.select { |r| r["score"] >= min_score }
          end

          # 如果使用 Pgvector，则直接返回 records
          return records if LangchainrbRails.config.vectorsearch.is_a?(Langchain::Vectorsearch::Pgvector)

          # 处理结果
          if LangchainrbRails.config.vectorsearch.is_a?(Langchain::Vectorsearch::Qdrant)
            # 提取ID和分数
            record_data = records.map do |record|
              id = record.dig("payload", "id") || record.dig("id")
              score = record["score"]
              { id: id, score: score }
            end

            # 查询数据库记录
            ids = record_data.map { |data| data[:id] }
            db_records = where(id: ids)

            # 如果需要返回分数，将分数附加到记录上
            if return_scores
              # 创建ID到分数的映射
              id_to_score = record_data.each_with_object({}) { |data, hash| hash[data[:id]] = data[:score] }

              # 为每个记录添加score方法
              db_records.each do |record|
                score = id_to_score[record.id.to_s]
                record.define_singleton_method(:score) { score }
              end
            end

            db_records
          else
            # 原有 Weaviate 逻辑
            record_data = records.map do |record|
              id = record.try("id") || record.dig("__id")
              score = record["score"] if record.is_a?(Hash) && record.key?("score")
              { id: id, score: score }
            end

            ids = record_data.map { |data| data[:id] }
            db_records = where(id: ids)

            # 如果需要返回分数，将分数附加到记录上
            if return_scores && record_data.first[:score]
              id_to_score = record_data.each_with_object({}) { |data, hash| hash[data[:id]] = data[:score] }

              db_records.each do |record|
                score = id_to_score[record.id.to_s]
                record.define_singleton_method(:score) { score }
              end
            end

            db_records
          end
        end
      end
    end
  end
end

# 将补丁应用到 ActiveRecord::Base
ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.include(LangchainrbRails::ActiveRecord::Hooks)
end
