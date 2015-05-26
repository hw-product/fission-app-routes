module FissionApp
  module Routes

    module RouteBasedNav

      def route_set_navigation
        nav, acct_nav = non_route_set_navigation
        if(isolated_product? && session[:route_id].to_i == 0)
          session[:route_id] = @account.routes_dataset.where(:name => @product.internal_name).first.try(:id) || 0
        end
        if(session[:route_id])
          @pipeline = @account.routes_dataset.where(:id => session[:route_id]).first
        end
        if(current_user.run_state.products.include?(Fission::Data::Models::Product.find_by_internal_name('routes')))
          pipe_list = Smash.new.tap do |pipes|
            @account.routes.each do |route|
              pipes[route.name.humanize] = Rails.application.routes.url_helpers.route_path(route.id)
            end
            pipes['break'] = nil
            pipes['New'] = Rails.application.routes.url_helpers.new_route_path
          end
          if(@pipeline || isolated_product?)
            if(@pipeline)
              @navigation = Smash.new.tap do |_nav|
                unless(isolated_product?)
                  _nav[@pipeline.name.humanize] = pipe_list
                end
                _nav['Dashboard'] = pipeline_dashboard_path(:pipeline_name => @pipeline.name)
                _nav['Manage'] = edit_route_path(@pipeline.id)
                _nav['Repositories'] = pipeline_repositories_path(:pipeline_name => @pipeline.name)
                _nav['Jobs'] = pipeline_jobs_path(:pipeline_name => @pipeline.name)
              end
            else
              @navigation = Smash.new
            end
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
        # Root dashboard removes selected route when not in isolation mode
        c_b[:scrub_route] = lambda do|*_|
          if(!isolated_product? && session.delete(:route_id))
            @pipeline = nil
          end
        end
        # Auto-redirect to route creation when not in isolation mode
        # and account does not have any routes defined
        c_b[:new_route_when_no_routes] = lambda do |*_|
          if(!isolated_product? && !current_user.run_state.plans.empty? && @account.routes_dataset.count == 0)
            redirect_to new_route_path
          end
        end
        c_b[:send_to_product_dashboard] = lambda do |*_|
          if(isolated_product? && session[:route_id].to_i == 0)
            session[:route_id] = @account.routes_dataset.where(:name => @product.internal_name).first.try(:id) || 0
          end
          pipeline = @account.routes_dataset.where(:id => session[:route_id]).first
          if(pipeline)
            redirect_to pipeline_dashboard_path(:pipeline_name => pipeline.name)
          end
        end
        Rails.application.config.settings.set(:callbacks, :before, :dashboard, :summary, c_b)

        c_b = Rails.application.config.settings.fetch(:callbacks, :after, 'account/billing', :order, Smash.new)
        # Auto create custom route when plan is attached to service
        # group'ed product
        c_b[:plan_route_autocreation] = lambda do |*_|
          if(isolated_product? && @plan && @plan.product && @plan.product.service_group)
            unless(@account.routes_dataset.where(:name => @plan.product.internal_name).count > 0)
              route = Fission::Data::Models::Route.create(
                :name => @plan.product.internal_name,
                :account_id => @account.id,
                :description => @plan.product.service_group.description
              )
              @plan.product.service_group.services.each_with_index do |srv, idx|
                route.add_service(
                  :service => srv,
                  :position => idx
                )
              end
            end
          end
        end
        Rails.application.config.settings.set(:callbacks, :after, 'account/billing', :order, c_b)

        c_b = Rails.application.config.settings.fetch(:callbacks, :before, :routes, :dashboard, Smash.new)
        c_b[:add_repositories_if_none] = lambda do |*_|
          pipeline = @account.routes_dataset.where(:id => session[:route_id]).first
          if(pipeline && pipeline.repositories_dataset.count < 1)
            redirect_to pipeline_repositories_path(:pipeline_name => pipeline.name)
          end
        end
        Rails.application.config.settings.set(:callbacks, :before, :routes, :dashboard, c_b)

        product = Fission::Data::Models::Product.find_or_create(:name => 'Routes')
        feature = Fission::Data::Models::ProductFeature.find_or_create(
          :name => 'Editor',
          :product_id => product.id
        )
        permission = Fission::Data::Models::Permission.find_or_create(
          :name => 'Routes editor access',
          :pattern => '/routes.*'
        )
        unless(feature.permissions.include?(permission))
          feature.add_permission(permission)
        end

        feature = Fission::Data::Models::ProductFeature.find_or_create(
          :name => 'Pipeline views',
          :product_id => product.id
        )
        permission = Fission::Data::Models::Permission.find_or_create(
          :name => 'Routes pipeline view access',
          :pattern => '/pipeline.*'
        )
        unless(feature.permissions.include?(permission))
          feature.add_permission(permission)
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
