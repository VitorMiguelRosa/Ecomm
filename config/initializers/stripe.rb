Stripe.api_key = Rails.application.credentials.dig(:stripe, :secret_key)
Rails.application.credentials.dig(:stripe, :public_key)