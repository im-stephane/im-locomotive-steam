module Locomotive::Steam
  module Middlewares
    module Concerns
      module Recaptcha

        def is_recaptcha_valid?(slug, response_code)
          !is_recaptcha_required?(slug) || is_recaptcha_verified?(response_code)
        end

        def is_recaptcha_required?(slug)
          type = services.content_entry.get_type(slug)
          type&.recaptcha_required?
        end

        def is_recaptcha_verified?(response_code)
          services.recaptcha.verify(response_code).tap do |valid|
            liquid_assigns['recaptcha_invalid'] = !valid
          end
        end

        def build_invalid_recaptcha_entry(slug, entry_attributes)
          services.content_entry.build(slug, entry_attributes).tap do |entry|
            entry.errors.add(:recaptcha_invalid, true)
          end
        end

      end
    end
  end
end
