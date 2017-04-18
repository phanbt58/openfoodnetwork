class Api::Admin::ExchangeSerializer < ActiveModel::Serializer
  attributes :id, :sender_id, :receiver_id, :incoming, :variants, :receival_instructions, :pickup_time, :pickup_instructions
  attributes :tags, :tag_list

  has_many :enterprise_fees, serializer: Api::Admin::BasicEnterpriseFeeSerializer

  def variants
    variants = object.incoming? ? visible_incoming_variants : visible_outgoing_variants
    Hash[ object.variants.merge(variants).map { |v| [v.id, true] } ]
  end

  def tag_list
    object.tag_list.join(",") if object.tag_list
  end

  def tags
    object.tag_list.map{ |t| { text: t } } if object.tag_list
  end

  private

  def visible_incoming_variants
    if object.order_cycle.prefers_product_selection_from_coordinator_inventory_only?
      permitted_incoming_variants.visible_for(object.order_cycle.coordinator)
    else
      permitted_incoming_variants
    end
  end

  def visible_outgoing_variants
    if object.receiver.prefers_product_selection_from_inventory_only?
      permitted_outgoing_variants.visible_for(object.receiver)
    else
      permitted_outgoing_variants.not_hidden_for(object.receiver)
    end
  end

  def permitted_incoming_variants
    OpenFoodNetwork::OrderCyclePermissions.new(options[:current_user], object.order_cycle).
    visible_variants_for_incoming_exchanges_from(object.sender)
  end

  def permitted_outgoing_variants
    OpenFoodNetwork::OrderCyclePermissions.new(options[:current_user], object.order_cycle)
    .visible_variants_for_outgoing_exchanges_to(object.receiver)
  end
end
