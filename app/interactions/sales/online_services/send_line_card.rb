require "line_client"

module Sales
  module OnlineServices
    class SendLineCard < ActiveInteraction::Base
      object :relation, class: OnlineServiceCustomerRelation

      def execute
        template =
          if relation.legal_to_access? && product.membership? && product.episodes.available.exists?
            contents = product.episodes.available.order("id DESC").limit(5).map do |episode|
              compose(Templates::Episode, episode: episode, social_customer: social_customer)
            end

            LineMessages::FlexTemplateContainer.carousel_template(
              altText: I18n.t("line.bot.messages.online_services.available_episodes"),
              contents: contents
            )
          else
            LineMessages::FlexTemplateContainer.template(
              altText: I18n.t("notifier.online_service.purchased.#{product.solution_type_for_message}.message", service_title: sale_page.product.name, service_url: ""),
              contents: compose(Templates::OnlineService, online_service_customer_relation: relation)
            )
          end

        ::LineClient.flex(social_customer, template)
      end

      private

      def product
        @product ||= sale_page.product
      end

      def sale_page
        @sale_page ||= relation.sale_page
      end

      def social_customer
        @social_customer ||= relation.customer.social_customer
      end
    end
  end
end
