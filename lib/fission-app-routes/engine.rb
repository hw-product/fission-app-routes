module FissionApp
  module Routes
    class Engine < ::Rails::Engine

      config.to_prepare do |config|
        product = Fission::Data::Models::Product.find_by_internal_name('routes')
        unless(product)
          product = Fission::Data::Models::Product.create(
            :name => 'Routes'
          )
        end
        feature = Fission::Data::Models::ProductFeature.find_by_name('routes_full_access')
        unless(feature)
          feature = Fission::Data::Models::ProductFeature.create(
            :name => 'routes_full_access',
            :product_id => product.id
          )
        end
        unless(feature.permissions_dataset.where(:name => 'routes_full_access').count > 0)
          args = {:name => 'routes_full_access', :pattern => '/routes.*'}
          permission = Fission::Data::Models::Permission.where(args).first
          unless(permission)
            permission = Fission::Data::Models::Permission.create(args)
          end
          unless(feature.permissions.include?(permission))
            feature.add_permission(permission)
          end
        end
      end

      # @return [Array<Fission::Data::Models::Product>]
      def fission_product
        [Fission::Data::Models::Product.find_by_internal_name('routes')]
      end

      # @return [Hash] navigation
      def fission_navigation(product, current_user)
        Smash.new(
          'Routes' => Rails.application.routes.url_helpers.routes_path
        )
      end

    end
  end
end
