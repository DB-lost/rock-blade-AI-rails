class SmsService
  class << self
    def send_code(phone)
      # 验证手机号格式
      return false unless phone.match?(/\A\+?[\d\-\s]+\z/)

      code = generate_code
      # 存储验证码到缓存
      Rails.cache.write("sms_code:#{normalize_phone(phone)}", code, expires_in: 5.minutes)
      # 调用短信API发送验证码
      send_sms(phone, code)
    end

    def verify_code(phone, code)
      return false if phone.blank? || code.blank?
      stored_code = Rails.cache.read("sms_code:#{normalize_phone(phone)}")
      return false if stored_code.nil?

      # 验证成功后删除缓存的验证码
      if stored_code == code
        Rails.cache.delete("sms_code:#{normalize_phone(phone)}")
        true
      else
        false
      end
    end

    private

    def generate_code
      rand(100000..999999).to_s
    end

    def send_sms(phone, code)
      # TODO: 实现实际的短信发送逻辑
      Rails.logger.info "Sending SMS to #{phone} with code #{code}"
      true
    end

    def normalize_phone(phone)
      # 移除所有非数字字符
      number = phone.to_s.gsub(/[^\d]/, "")
      # 如果以86开头，移除它
      number = number[2..-1] if number.start_with?("86")
      number
    end
  end
end
