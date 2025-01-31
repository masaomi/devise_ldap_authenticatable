require "net/ldap"

module Devise
  module LDAP
    DEFAULT_GROUP_UNIQUE_MEMBER_LIST_KEY = 'uniqueMember'
    
    module Adapter
      def self.valid_credentials?(login, password_plaintext)
        options = {:login => login,
                   :password => password_plaintext,
                   :ldap_auth_username_builder => ::Devise.ldap_auth_username_builder,
                   :admin => ::Devise.ldap_use_admin_to_bind}

        ldap_config = YAML.load(ERB.new(File.read(::Devise.ldap_config || "#{Rails.root}/config/ldap.yml")).result)[Rails.env]
        bases = ldap_config["base"]
        bases = [bases] unless bases.is_a?(Array)
        bases.each do |base|
        # Initializer now accepts a second parameter: base
          resource = Devise::LDAP::Connection.new(options, base)
          if resource.authorized?
            return true
          end
        end
        false
      end

      def self.expired_valid_credentials?(login, password_plaintext)
        options = {:login => login,
                   :password => password_plaintext,
                   :ldap_auth_username_builder => ::Devise.ldap_auth_username_builder,
                   :admin => ::Devise.ldap_use_admin_to_bind}

        resource = Devise::LDAP::Connection.new(options)
        resource.expired_valid_credentials?
      end

      def self.update_password(login, new_password)
        options = {:login => login,
                   :new_password => new_password,
                   :ldap_auth_username_builder => ::Devise.ldap_auth_username_builder,
                   :admin => ::Devise.ldap_use_admin_to_bind}

        resource = Devise::LDAP::Connection.new(options)
        resource.change_password! if new_password.present?
      end

      def self.update_own_password(login, new_password, current_password)
        set_ldap_param(login, :userPassword, ::Devise.ldap_auth_password_builder.call(new_password), current_password)
      end

      def self.ldap_connect(login)
        options = {:login => login,
                   :ldap_auth_username_builder => ::Devise.ldap_auth_username_builder,
                   :admin => ::Devise.ldap_use_admin_to_bind}

        Devise::LDAP::Connection.new(options)
      end

      def self.valid_login?(login)
        self.ldap_connect(login).valid_login?
      end

      def self.get_groups(login)
        self.ldap_connect(login).user_groups
      end

      def self.in_ldap_group?(login, group_name, group_attribute = nil)
        self.ldap_connect(login).in_group?(group_name, group_attribute)
      end

      def self.get_dn(login)
        self.ldap_connect(login).dn
      end

      def self.set_ldap_param(login, param, new_value, password = nil)
        options = {:login => login,
                   :ldap_auth_username_builder => ::Devise.ldap_auth_username_builder,
                   :password => password }

        resource = Devise::LDAP::Connection.new(options)
        resource.set_param(param, new_value)
      end

      def self.delete_ldap_param(login, param, password = nil)
        options = {:login => login,
                   :ldap_auth_username_builder => ::Devise.ldap_auth_username_builder,
                   :password => password }

        resource = Devise::LDAP::Connection.new(options)
        resource.delete_param(param)
      end

      def self.get_ldap_param(login,param)
        resource = self.ldap_connect(login)
        resource.ldap_param_value(param)
      end

      def self.get_ldap_entry(login)
        self.ldap_connect(login).search_for_login
      end
    end
  end
end
