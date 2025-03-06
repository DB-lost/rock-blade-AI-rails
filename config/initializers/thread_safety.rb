# 确保Rails应用可以安全地使用线程
#
# 此配置用于支持我们的AI聊天服务中的后台线程处理

# 对于Rails 7+，默认已经是线程安全的，但我们需要确保与ActiveRecord连接池的正确交互
ActiveSupport.on_load(:active_record) do
  # 在应用关闭时断开所有数据库连接
  at_exit do
    ActiveRecord::Base.connection_pool.disconnect! if ActiveRecord::Base.connected?
  end

  # 设置连接池大小，确保有足够的连接来处理并发请求和后台线程
  pool_size = [ 5, ENV.fetch("RAILS_MAX_THREADS", 5).to_i ].max
  db_config = ActiveRecord::Base.connection_pool.db_config
  ActiveRecord::Base.establish_connection(
    db_config.configuration_hash.merge(pool: pool_size)
  )
end

# 确保后台线程正确处理异常
Thread.abort_on_exception = Rails.env.development? || Rails.env.test?
