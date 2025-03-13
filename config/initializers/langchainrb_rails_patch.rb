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
        def similarity_search(query, k: 1, user_id: nil)
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

          # 如果使用 Pgvector，则直接返回 records
          return records if LangchainrbRails.config.vectorsearch.is_a?(Langchain::Vectorsearch::Pgvector)

          # 如果是 Qdrant，解析出记录 id，然后返回 AR 对象
          if LangchainrbRails.config.vectorsearch.is_a?(Langchain::Vectorsearch::Qdrant)
            ids = records.map { |record| record.dig("payload", "id") || record.dig("id") }
            return where(id: ids)
          end

          # 原有 Weaviate 逻辑
          ids = records.map { |record| record.try("id") || record.dig("__id") }
          where(id: ids)
        end
      end
    end
  end
end

# 将补丁应用到 ActiveRecord::Base
ActiveSupport.on_load(:active_record) do
  ActiveRecord::Base.include(LangchainrbRails::ActiveRecord::Hooks)
end
