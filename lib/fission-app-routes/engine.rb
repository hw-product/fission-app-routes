module FissionApp
  module Routes

    module RouteBasedNav

      def route_set_navigation
        nav, acct_nav = non_route_set_navigation
        if(session[:route_id])
          @pipeline = @account.routes_dataset.where(:id => session[:route_id]).first
        end
        if(@account.products.include?(Fission::Data::Models::Product.find_by_internal_name('routes')))
          pipe_list = Smash.new.tap do |pipes|
            @account.routes.each do |route|
              pipes[route.name.humanize] = Rails.application.routes.url_helpers.route_path(route.id)
            end
            pipes['break'] = nil
            pipes['New'] = Rails.application.routes.url_helpers.new_route_path
          end
          if(@pipeline)
            @navigation = Smash.new(
              @pipeline.name.humanize => pipe_list,
              'Dashboard' => pipeline_dashboard_path(:pipeline_name => @pipeline.name),
              'Repositories' => pipeline_repositories_path(:pipeline_name => @pipeline.name),
              'Jobs' => pipeline_jobs_path(:pipeline_name => @pipeline.name)
            )
          else
            @navigation = Smash.new(
              'Pipelines' => pipe_list
            ).merge(nav)
          end
        end
        [@navigation, acct_nav]
      end

      def self.included(klass)
        klass.class_eval do
          alias_method :non_route_set_navigation, :set_navigation
          alias_method :set_navigation, :route_set_navigation
        end
      end

    end

    class Engine < ::Rails::Engine

      config.to_prepare do |config|

        # Hooks!

        c_b = Rails.application.config.settings.fetch(:callbacks, :before, :dashboard, :summary, Smash.new)
        c_b[:scrub_route] = lambda{|*_|
          if(session.delete(:route_id))
            @pipeline = nil
          end
        }
        Rails.application.config.settings.set(:callbacks, :before, :dashboard, :summary, c_b)

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

        feature = Fission::Data::Models::ProductFeature.find_by_name('routes_pipeline_access')
        unless(feature)
          feature = Fission::Data::Models::ProductFeature.create(
            :name => 'routes_pipeline_access',
            :product_id => product.id
          )
        end
        unless(feature.permissions_dataset.where(:name => 'routes_pipeline_access').count > 0)
          args = {:name => 'routes_pipeline_access', :pattern => '/pipeline.*'}
          permission = Fission::Data::Models::Permission.where(args).first
          unless(permission)
            permission = Fission::Data::Models::Permission.create(args)
          end
          unless(feature.permissions.include?(permission))
            feature.add_permission(permission)
          end
        end

        [ApplicationController, *ApplicationController.descendants].each do |klass|
          klass.send(:include, RouteBasedNav)
        end

      end

      # @return [Array<Fission::Data::Models::Product>]
      def fission_product
        [Fission::Data::Models::Product.find_by_internal_name('routes')]
      end

      # @return [Smash]
      def fission_dashboard(product, current_user)
        routes = current_user.run_state.current_account.routes_dataset.order(:name).all
        Smash.new.tap do |dash|
          routes.each do |route|
            dash[route.name] = Smash.new(
              :cell => :default_route_dashboard,
              :title => "#{route.name.humanize} Pipeline",
              :url => Rails.application.routes.url_helpers.route_path(route.id),
              :arguments => {
                :route => route
              }
            )
          end
        end
      end

    end
  end
end
