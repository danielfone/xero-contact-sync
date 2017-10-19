module Xero
  class Contact < ApplicationRecord
    DEEP_LINK_URL = "https://go.xero.com/organisationlogin/default.aspx?" \
      "shortcode=%<shortcode>s&" \
      "redirecturl=%<target_url>s"

    scope :active, -> { where status: 'ACTIVE' }

    def self.upsert_api_response(results, org_code)
      transaction do
        Array.wrap(results).each do |result|
          upsert_api_result(result, org_code)
        end
      end
    end

    def self.upsert_api_result(contact, org_code)
      # https://github.com/jesjos/active_record_upsert
      upsert(
        id: contact[:contact_id],
        name: contact[:name],
        org_code: org_code,
        status: (contact[:contact_status] || 'ACTIVE'),
        updated_at: contact[:updated_date_utc],
        synced_at: Time.current,
        data: contact.to_h,
      )
    end

    def self.last_updated_at
      maximum(:updated_at)
    end

    def self.last_synced_at
      maximum(:synced_at)
    end

    # https://developer.xero.com/documentation/api-guides/deep-link-xero
    def xero_url
      target = "/Contacts/View.aspx?contactID=#{id}"
      format(DEEP_LINK_URL, shortcode: org_code, target_url: target)
    end

    def muted?
      status == 'ARCHIVED'
    end

    def outstanding_balance
      data.dig('balances', 'accounts_receivable', 'outstanding')
    end
  end
end
