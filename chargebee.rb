{
  title: 'Chargebee',

  connection: {
    fields: [
      { name: 'api_key', label: 'API key',
        control_type: 'password', optional: false,
        hint: 'Chargebee API Key of the Customer,' \
        "Click <a href='https://www.chargebee.com/docs/api_keys.html' target='blank'>here" \
        '</a> for more details. The API Key should have access to both v1 and v2' },
      { name: 'subdomain', control_type: 'subdomain', url: '.chargebee.com',
        optional: false, hint: 'Chargebee domain name of the customer' }
    ],
    authorization: {
      type: 'basic_auth',
      apply: lambda do |connection|
        unless current_url.include?('.pdf?response-content-disposition=attachment')
          user(connection['api_key'])
        end
      end
    },
    base_uri: lambda do |connection|
      "https://#{connection['subdomain']}.chargebee.com/api/v2/"
    end
  },

  test: lambda do |_connection|
    get('customers').params(limit: 1)
  end,

  methods: {
    format_create_input: lambda do |input|
      input = input.each_with_object({}) do |(key, value), hash|
        if value.is_a?(Array)
          if value.first.is_a?(Hash)
            value.each_with_index do |item, count|
              item.each do |k, v|
                hash["#{key}[#{k}][#{count}]"] = v
                hash
              end
            end
          else
            value.each_with_index do |item, count|
              hash["#{key}[#{count}]"] = item
              hash
            end
          end
        else
          hash[key] = value
        end
      end
    end,
    make_schema_builder_fields_sticky: lambda do |schema|
      schema.map do |field|
        if field['properties'].present?
          field['properties'] = call('make_schema_builder_fields_sticky',
                                     field['properties'])
        end
        field['sticky'] = true

        field
      end
    end,
    format_schema: lambda do |input|
      input&.map do |field|
        if (props = field[:properties])
          field[:properties] = call('format_schema', props)
        elsif (props = field['properties'])
          field['properties'] = call('format_schema', props)
        end
        if (name = field[:name])
          field[:label] = field[:label].presence || name.labelize
          field[:name] = name.
                         gsub(/\W/) { |spl_chr| "__#{spl_chr.encode_hex}__" }
        elsif (name = field['name'])
          field['label'] = field['label'].presence || name.labelize
          field['name'] = name.
                          gsub(/\W/) { |spl_chr| "__#{spl_chr.encode_hex}__" }
        end

        field
      end
    end,
    format_payload: lambda do |payload|
      if payload.is_a?(Array)
        payload.map do |array_value|
          call('format_payload', array_value)
        end
      elsif payload.is_a?(Hash)
        payload.each_with_object({}) do |(key, value), hash|
          key = key.gsub(/__\w+__/) do |string|
            string.gsub(/__/, '').decode_hex.as_utf8
          end
          if value.is_a?(Array) || value.is_a?(Hash)
            value = call('format_payload', value)
          end
          hash[key] = value
        end
      end
    end,
    format_response: lambda do |response|
      response = response&.compact unless response.is_a?(String) || response
      if response.is_a?(Array)
        response.map do |array_value|
          call('format_response', array_value)
        end
      elsif response.is_a?(Hash)
        response.each_with_object({}) do |(key, value), hash|
          key = key.gsub(/\W/) { |spl_chr| "__#{spl_chr.encode_hex}__" }
          if value.is_a?(Array) || value.is_a?(Hash)
            value = call('format_response', value)
          end
          hash[key] = value
        end
      else
        response
      end
    end,
    epoch_to_iso: lambda do |input|
      input&.to_i&.to_time&.iso8601
    end,
    plan_schema: lambda do |input|
      fields = [
        { name: 'id' },
        { name: 'name' },
        { name: 'invoice_name' },
        { name: 'description' },
        { name: 'trial_period', type: 'integer', control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'trial_period_unit' },
        { name: 'period', type: 'integer', control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'period_unit' },
        { name: 'charge_model' },
        { name: 'setup_cost', type: 'number', control_type: 'number' },
        { name: 'price', type: 'number', control_type: 'number' },
        { name: 'price_in_decimal' },
        { name: 'currency_code' },
        { name: 'resource_version', type: 'number', control_type: 'number' },
        { name: 'archived_at', type: 'date_time', control_type: 'date_time',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'billing_cycles', type: 'integer', control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'pricing_model' },
        { name: 'free_quantity', type: 'integer', control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'free_quantity_in_decimal' },
        { name: 'addon_applicability', label: 'Add-on applicability' },
        { name: 'redirect_url' },
        { name: 'enabled_in_hosted_pages',
          type: 'boolean', control_type: 'checkbox',
          convert_output: 'boolean_conversion' },
        { name: 'enabled_in_portal',
          type: 'boolean', control_type: 'checkbox',
          convert_output: 'boolean_conversion' },
        { name: 'taxable',
          type: 'boolean', control_type: 'checkbox',
          convert_output: 'boolean_conversion' },
        { name: 'tax_profile_id' },
        { name: 'tax_code' },
        { name: 'hsn_code', label: 'HSN code',
          hint: 'The HSN code to which the item is mapped for ' \
                'calculating the customer’s tax in India.' },
        { name: 'taxjar_product_code' },
        { name: 'avalara_sale_type' },
        { name: 'avalara_transaction_type', type: 'integer', control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'avalara_service_type', type: 'integer', control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'sku', label: 'SKU' },
        { name: 'trial_end_action' },
        { name: 'accounting_code' },
        { name: 'accounting_category1' },
        { name: 'accounting_category2' },
        { name: 'accounting_category3' },
        { name: 'accounting_category4' },
        { name: 'is_shippable',
          type: 'boolean', control_type: 'checkbox',
          convert_output: 'boolean_conversion' },
        { name: 'shipping_frequency_period', type: 'integer', control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'shipping_frequency_period_unit' },
        { name: 'invoice_notes' },
        { name: 'show_description_in_invoices',
          type: 'boolean', control_type: 'checkbox',
          convert_output: 'boolean_conversion' },
        { name: 'show_description_in_quotes',
          type: 'boolean', control_type: 'checkbox',
          convert_output: 'boolean_conversion' },
        { name: 'giftable',
          type: 'boolean', control_type: 'checkbox',
          convert_output: 'boolean_conversion' },
        { name: 'updated_at', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
        { name: 'status' },
        { name: 'claim_url' },
        { name: 'tiers', type: 'array', of: 'object',
          properties: [
            { name: 'starting_unit', type: 'integer', control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'ending_unit', type: 'integer', control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'price', type: 'number', control_type: 'number' },
            { name: 'starting_unit_in_decimal' },
            { name: 'ending_unit_in_decimal' },
            { name: 'price_in_decimal' }
          ] },
        { name: 'applicable_addons', type: 'array', of: 'object',
          properties: [
            { name: 'id' }
          ] },
        { name: 'attached_addons', type: 'array', of: 'object',
          properties: [
            { name: 'id' },
            { name: 'quantity', type: 'integer', control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'billing_cycles', type: 'integer', control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'type' },
            { name: 'quantity_in_decimal' }
          ] },
        { name: 'event_based_addons', type: 'array', of: 'object',
          properties: [
            { name: 'id' },
            { name: 'quantity', type: 'integer', control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'on_event' },
            { name: 'charge_once', type: 'boolean', control_type: 'checkbox',
              convert_output: 'boolean_conversion' },
            { name: 'quantity_in_decimal' }
          ] }
      ]
      if input['schema_builder'].present?
        fields.concat([
                        { name: 'meta_data', type: 'object',
                          properties: parse_json(input['schema_builder']) }
                      ])
      else
        fields
      end
    end,
    invoice_schema: lambda do |_input|
      [
        { name: 'id' },
        { name: 'customer_id', sticky: true,
          hint: 'Identifier of the customer for which this invoice needs to be created. ' \
                'Should be specified if subscription_id is not specified.' },
        { name: 'subscription_id', sticky: true,
          hint: 'Identifier of the subscription for which this invoice needs to be created. ' \
                'Should be specified if customer_id is not specified.(not applicable ' \
                'for consolidated invoice).' },
        { name: 'po_number', label: 'Purchase order number' },
        { name: 'recurring', type: 'boolean', control_type: 'checkbox',
          convert_output: 'boolean_conversion' },
        { name: 'status' },
        { name: 'auto_collection',
          control_type: 'select',
          pick_list: 'auto_collection_list',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'auto_collection',
            type: 'string',
            control_type: 'text',
            label: 'Auto collection',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are <b>on, off</b>'
          },
          hint: 'Whether payments needs to be ' \
                'collected automatically for this customer.' },
        { name: 'token_id', sticky: true,
          hint: 'Token generated by Chargebee JS representing payment method details.' },
        { name: 'coupon_ids', label: 'Coupon IDs', sticky: true, type: 'array', of: 'string' },
        { name: 'authorization_transaction_id', sticky: true,
          hint: 'Authorization transaction to be captured.' },
        { name: 'payment_source_id', sticky: true,
          hint: 'Payment source to be used for this payment.' },
        { name: 'invoice_date', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
        { name: 'vat_number', label: 'VAT/ Tax registration number' },
        { name: 'price_type', label: 'Price type' },
        { name: 'date', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
        { name: 'due_date', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp',
          label: 'Due date' },
        { name: 'net_term_days', type: 'integer', control_type: 'integer',
          convert_output: 'integer_conversion', label: 'Net term days' },
        { name: 'currency_code',
          hint: 'The currency code (ISO 4217 format) of the invoice amount. Required ' \
                'if Multicurrency is enabled' },
        { name: 'invoice_note' },
        { name: 'total', type: 'number', control_type: 'number' },
        { name: 'amount_paid', type: 'number', control_type: 'number',
          label: 'Amount paid' },
        { name: 'amount_adjusted', type: 'number', control_type: 'number',
          label: 'Amount adjusted' },
        { name: 'write_off_amount', type: 'number', control_type: 'number',
          label: 'Write off amount' },
        { name: 'credits_applied', type: 'number', control_type: 'number',
          label: 'Credits applied' },
        { name: 'amount_due', type: 'number', control_type: 'number',
          label: 'Amount due' },
        { name: 'paid_at', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp',
          label: 'Paid at' },
        { name: 'remove_general_note',
          type: 'boolean',
          control_type: 'checkbox',
          convert_output: 'boolean_conversion',
          toggle_hint: 'Select from list',
          convert_input: 'boolean_conversion',
          toggle_field: { name: 'remove_general_note',
                          label: 'Remove general note',
                          type: 'string',
                          control_type: 'text',
                          optional: true,
                          sticky: true,
                          convert_output: 'boolean_conversion',
                          convert_input: 'boolean_conversion',
                          hint: 'Accepted values are true or false',
                          toggle_hint: 'Use custom value' } },
        { name: 'replace_primary_payment_source',
          type: 'boolean',
          control_type: 'checkbox',
          convert_output: 'boolean_conversion',
          toggle_hint: 'Select from list',
          convert_input: 'boolean_conversion',
          toggle_field: { name: 'replace_primary_payment_source',
                          label: 'Replace primary payment source',
                          type: 'string',
                          control_type: 'text',
                          optional: true,
                          sticky: true,
                          convert_output: 'boolean_conversion',
                          convert_input: 'boolean_conversion',
                          hint: 'Accepted values are true or false',
                          toggle_hint: 'Use custom value' } },
        { name: 'retain_payment_source',
          type: 'boolean',
          control_type: 'checkbox',
          convert_output: 'boolean_conversion',
          toggle_hint: 'Select from list',
          convert_input: 'boolean_conversion',
          toggle_field: { name: 'retain_payment_source',
                          label: 'Retain payment source',
                          type: 'string',
                          control_type: 'text',
                          optional: true,
                          sticky: true,
                          convert_output: 'boolean_conversion',
                          convert_input: 'boolean_conversion',
                          hint: 'Accepted values are true or false',
                          toggle_hint: 'Use custom value' } },
        { name: 'dunning_status', label: 'Dunning status' },
        { name: 'next_retry_at', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp',
          label: 'Next retry at' },
        { name: 'voided_at', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp',
          label: 'Voided at' },
        { name: 'resource_version', type: 'number', control_type: 'number',
          label: 'Resource version' },
        { name: 'updated_at', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp',
          label: 'Updated at' },
        { name: 'sub_total', type: 'number', control_type: 'number',
          label: 'Sub total' },
        { name: 'sub_total_in_local_currency', type: 'number',
          control_type: 'number',
          label: 'Sub total in local currency' },
        { name: 'total_in_local_currency', type: 'number',
          control_type: 'number',
          label: 'Total in local currency' },
        { name: 'local_currency_code', label: 'Local currency code' },
        { name: 'tax', type: 'number', control_type: 'number' },
        { name: 'first_invoice', type: 'boolean', control_type: 'checkbox',
          convert_output: 'boolean_conversion', label: 'First invoice' },
        { name: 'has_advance_charges', type: 'boolean', control_type: 'checkbox',
          convert_output: 'boolean_conversion', label: 'Has advance charges' },
        { name: 'term_finalized', type: 'boolean', control_type: 'checkbox',
          convert_output: 'boolean_conversion', label: 'Term finalized' },
        { name: 'is_gifted', type: 'boolean', control_type: 'checkbox',
          convert_output: 'boolean_conversion', label: 'Is gifted' },
        { name: 'expected_payment_date', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp',
          label: 'Expected payment date' },
        { name: 'amount_to_collect', type: 'number', control_type: 'number',
          label: 'Amount to collect' },
        { name: 'vat_number_prefix', label: 'VAT number prefix' },
        { name: 'generated_at', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
        { name: 'exchange_rate', type: 'integer', control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'new_sales_amount', type: 'integer', control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'base_currency_code' },
        { name: 'round_off_amount', type: 'number', control_type: 'number',
          label: 'Round off amount' },
        { name: 'payment_owner', label: 'Payment owner' },
        { name: 'void_reason_code', label: 'Void reason code' },
        { name: 'deleted', type: 'boolean', control_type: 'checkbox',
          convert_output: 'boolean_conversion' },
        { name: 'line_items', type: 'array', of: 'object', properties: [
          { name: 'id' },
          { name: 'subscription_id', label: 'Subscription ID' },
          { name: 'date_from', type: 'date_time', control_type: 'date_time',
            convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp',
            label: 'Date from' },
          { name: 'date_to', type: 'date_time', control_type: 'date_time',
            convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp',
            label: 'Date to' },
          { name: 'unit_amount', type: 'number', control_type: 'number',
            label: 'Unit amount' },
          { name: 'quantity', type: 'integer', control_type: 'integer',
            convert_output: 'integer_conversion' },
          { name: 'amount', type: 'number', control_type: 'number' },
          { name: 'pricing_model', label: 'Pricing model' },
          { name: 'is_taxed', type: 'boolean', control_type: 'checkbox',
            convert_output: 'boolean_conversion', label: 'Is taxed' },
          { name: 'tax_amount', type: 'number', control_type: 'number',
            label: 'Tax amount' },
          { name: 'tax_rate', type: 'number', control_type: 'number',
            label: 'Tax rate' },
          { name: 'unit_amount_in_decimal', label: 'Unit amount in decimal' },
          { name: 'quantity_in_decimal', label: 'Quantity in decimal' },
          { name: 'amount_in_decimal', label: 'Amount in decimal' },
          { name: 'discount_amount', type: 'number', control_type: 'number' },
          { name: 'item_level_discount_amount', type: 'number',
            control_type: 'number',
            label: 'Item level discount amount' },
          { name: 'description' },
          { name: 'entity_description', label: 'Entity description' },
          { name: 'entity_type', label: 'Entity type' },
          { name: 'tax_exempt_reason', label: 'Tax exempt reason' },
          { name: 'entity_id', label: 'Entity ID' },
          { name: 'customer_id', label: 'Customer ID' }
        ] },
        { name: 'discounts', type: 'array', of: 'object', properties: [
          { name: 'amount', type: 'number', control_type: 'number' },
          { name: 'description' },
          { name: 'line_item_id' },
          { name: 'entity_type', label: 'Entity type' },
          { name: 'entity_id', label: 'Entity ID' }
        ] },
        { name: 'line_item_discounts', type: 'array', of: 'object', properties: [
          { name: 'line_item_id', label: 'Line item ID' },
          { name: 'discount_type', label: 'Discount type' },
          { name: 'coupon_id', label: 'Coupon ID' },
          { name: 'discount_amount', type: 'number', control_type: 'number',
            label: 'Discount amount' }
        ] },
        { name: 'taxes', type: 'array', of: 'object', properties: [
          { name: 'name' },
          { name: 'amount', type: 'number', control_type: 'number' },
          { name: 'description' }
        ] },
        { name: 'line_item_taxes', type: 'array', of: 'object', properties: [
          { name: 'line_item_id', label: 'Line item ID' },
          { name: 'tax_name', label: 'Tax name' },
          { name: 'tax_rate', type: 'number', control_type: 'number',
            label: 'Tax rate' },
          { name: 'is_partial_tax_applied', type: 'boolean', control_type: 'checkbox',
            convert_output: 'boolean_conversion',
            label: 'Is partial tax applied' },
          { name: 'is_non_compliance_tax', type: 'boolean',
            control_type: 'checkbox', convert_output: 'boolean_conversion',
            label: 'Is non compliance tax' },
          { name: 'taxable_amount', type: 'number', control_type: 'number',
            label: 'Taxable amount' },
          { name: 'tax_amount', type: 'number', control_type: 'number',
            label: 'Tax amount' },
          { name: 'tax_juris_type', label: 'Tax juris type' },
          { name: 'tax_juris_name', label: 'Tax juris name' },
          { name: 'tax_juris_code', label: 'Tax juris code' },
          { name: 'tax_amount_in_local_currency', type: 'number',
            control_type: 'number', label: 'Tax amount in local currency' },
          { name: 'local_currency_code', label: ' Local currency code' }
        ] },
        { name: 'line_item_tiers', type: 'array', of: 'object', properties: [
          { name: 'line_item_id', label: 'Line item ID' },
          { name: 'starting_unit', type: 'integer', control_type: 'integer',
            convert_output: 'integer_conversion', label: 'Starting unit' },
          { name: 'ending_unit', type: 'integer', control_type: 'integer',
            convert_output: 'integer_conversion', label: 'Ending unit' },
          { name: 'quantity_used', type: 'integer', control_type: 'integer',
            convert_output: 'integer_conversion', label: 'Quantity used' },
          { name: 'unit_amount', type: 'number', control_type: 'number',
            label: 'Unit amount' },
          { name: 'starting_unit_in_decimal', label: 'Starting unit in decimal' },
          { name: 'ending_unit_in_decimal', label: 'Ending unit in decimal' },
          { name: 'quantity_used_in_decimal', label: 'Quantity used in decimal' },
          { name: 'unit_amount_in_decimal', label: 'Unit amount in decimal' }
        ] },
        { name: 'linked_payments', type: 'array', of: 'object', properties: [
          { name: 'txn_id', label: 'Transaction ID' },
          { name: 'applied_amount', type: 'number', control_type: 'number',
            label: 'Applied amount' },
          { name: 'applied_at', type: 'date_time', control_type: 'date_time',
            convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp',
            label: 'Applied at' },
          { name: 'txn_status', label: 'Transaction status' },
          { name: 'txn_date', type: 'date_time', control_type: 'date_time',
            convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp',
            label: 'Transaction date' },
          { name: 'txn_amount', type: 'number', control_type: 'number',
            label: 'Transaction amount' }
        ] },
        { name: 'dunning_attempts', type: 'array', of: 'object', properties: [
          { name: 'attempt', type: 'integer', control_type: 'integer',
            convert_output: 'integer_conversion' },
          { name: 'transaction_id', label: 'Transaction ID' },
          { name: 'dunning_type', label: 'Dunning type' },
          { name: 'created_at', type: 'date_time', control_type: 'date_time',
            convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp',
            label: 'Created at' },
          { name: 'txn_status', label: 'Transaction status' },
          { name: 'txn_amount', type: 'number', control_type: 'number',
            label: 'Transaction amount' }
        ] },
        { name: 'applied_credits', type: 'array', of: 'object', properties: [
          { name: 'cn_id', label: 'Credit note ID' },
          { name: 'applied_amount', type: 'number', control_type: 'number',
            label: 'Applied amount' },
          { name: 'applied_at', type: 'date_time', control_type: 'date_time',
            convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp',
            label: 'Applied at' },
          { name: 'cn_reason_code', label: 'Credit note reason code' },
          { name: 'cn_create_reason_code', label: 'Credit note create reason code' },
          { name: 'cn_date', label: 'Credit note date',
            type: 'date_time', control_type: 'date_time',
            convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
          { name: 'cn_status', label: 'Credit note status' }
        ] },
        { name: 'adjustment_credit_notes', type: 'array', of: 'object',
          properties: [
            { name: 'cn_id', label: 'Credit note ID' },
            { name: 'cn_reason_code', label: 'Credit note reason code' },
            { name: 'cn_create_reason_code', label: 'Credit note create reason code' },
            { name: 'cn_date', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp',
              label: 'Credit note date' },
            { name: 'cn_status', label: 'Credit note status' },
            { name: 'cn_total', type: 'number', control_type: 'number',
              label: 'Credit note total' }
          ] },
        { name: 'issued_credit_notes', type: 'array', of: 'object',
          properties: [
            { name: 'cn_id', label: 'Credit note ID' },
            { name: 'cn_reason_code', label: 'Credit note reason code' },
            { name: 'cn_create_reason_code', label: 'Credit note create reason code' },
            { name: 'cn_date', label: 'Credit note date',
              type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
            { name: 'cn_status', label: 'Credit note status' },
            { name: 'cn_total', type: 'number', control_type: 'number',
              label: 'Credit note total' }
          ] },
        { name: 'linked_orders', type: 'array', of: 'object',
          properties: [
            { name: 'id' },
            { name: 'document_number', label: 'Document number' },
            { name: 'status' },
            { name: 'order_type', label: 'Order type' },
            { name: 'reference_id', label: 'Reference ID' },
            { name: 'fulfillment_status', label: 'Fulfillment status' },
            { name: 'batch_id', label: 'Batch ID' },
            { name: 'created_at', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp',
              label: 'Created at' }
          ] },
        { name: 'notes', type: 'array', of: 'object', properties: [
          { name: 'entity_type', label: 'Entity type' },
          { name: 'note' },
          { name: 'entity_id', label: 'Entity ID' }
        ] },
        { name: 'shipping_address', type: 'object', properties: [
          { name: 'first_name', label: 'First name' },
          { name: 'last_name', label: 'Last name' },
          { name: 'email' },
          { name: 'company' },
          { name: 'phone' },
          { name: 'line1' },
          { name: 'line2' },
          { name: 'line3' },
          { name: 'city' },
          { name: 'state_code' },
          { name: 'state' },
          { name: 'country' },
          { name: 'zip' },
          { name: 'validation_status', control_type: 'select',
            pick_list: 'validation_status_list',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'validation_status', control_type: 'text',
              type: 'string', optional: true,
              label: 'Customer type',
              toggle_hint: 'Use custom value',
              hint: 'Allowed vaalues are: not_validated, valid, partially_valid, invalid'
            },
            hint: 'The address verification status.' }
        ] },
        { name: 'payment_intent', type: 'object',
          properties: [
            { name: 'id', label: 'Payment intent ID',
              hint: 'Payment intent ID generated by Chargebee.js' },
            { name: 'gateway_account_id',
              hint: 'Gateway account used for performing the 3DS flow.' },
            { name: 'gw_token', label: 'Gateway token',
              hint: 'Identifier for 3DS transaction/verification object at the gateway.' },
            { name: 'reference_id',
              hint: 'Identifier for Braintree permanent token. Applicable when you are ' \
                    'using Braintree APIs for completing the 3DS flow.' },
            { name: 'additional_info', label: 'Additional information',
              hint: 'Pass a stringified JSON. For E.g: click <a href=' \
                "'https://apidocs.chargebee.com/docs/api/payment_parameters" \
                "#payment_intent_additonal_info_sample'>" \
                'here<a> to see sample json.' }
          ] },
        { name: 'einvoice', label: 'E-invoice', type: 'object',
          properties: [
            { name: 'id' },
            { name: 'status' },
            { name: 'message' }
          ] },
        { name: 'linked_tax_withheld', type: 'array', of: 'object',
          properties: [
            { name: 'id' },
            { name: 'amount', type: 'intger', control_type: 'integer',
              convert_input: 'integer_conversion',
              convert_output: 'integer_conversion' },
            { name: 'description' },
            { name: 'date', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time',
              convert_output: 'render_iso8601_timestamp' },
            { name: 'reference_number' }
          ] },
        { name: 'billing_address', type: 'object',
          properties: call('business_address_schema', '') }
      ]
    end,
    unbilled_charge_schema: lambda do |_input|
      [
        { name: 'id' },
        { name: 'customer_id' },
        { name: 'subscription_id' },
        { name: 'date_from',
          type: 'date_time',
          control_type: 'date_time',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'date_to',
          type: 'date_time',
          control_type: 'date_time',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'voided_at',
          type: 'date_time',
          control_type: 'date_time',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'amount',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'currency_code' },
        { name: 'deleted',
          type: 'boolean',
          control_type: 'checkbox',
          convert_output: 'boolean_conversion' },
        { name: 'description' },
        { name: 'discount_amount',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'entity_id' },
        { name: 'entity_type' },
        { name: 'is_voided',
          type: 'boolean',
          control_type: 'checkbox',
          convert_output: 'boolean_conversion' },
        { name: 'object' },
        { name: 'pricing_model' },
        { name: 'quantity',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'unit_amount_in_decimal' },
        { name: 'quantity_in_decimal' },
        { name: 'amount_in_decimal' },
        { name: 'unit_amount',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'tiers',
          type: 'array',
          of: 'object',
          properties: [
            { name: 'starting_unit',
              type: 'integer',
              control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'ending_unit',
              type: 'integer',
              control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'quantity_used',
              type: 'integer',
              control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'unit_amount',
              type: 'integer',
              control_type: 'number',
              convert_output: 'integer_conversion' },
            { name: 'starting_unit_in_decimal' },
            { name: 'ending_unit_in_decimal' },
            { name: 'quantity_used_in_decimal' },
            { name: 'unit_amount_in_decimal' }
          ] }
      ]
    end,
    card_schema: lambda do
      [
        { name: 'payment_source_id' },
        { name: 'status', control_type: 'select',
          pick_list: 'card_status_list',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'status', control_type: 'text',
            type: 'string',
            label: 'Card status',
            toggle_hint: 'Use custom value',
            hint: 'Current status of the card. Allowed values are: valid, ' \
              'expiring, expired'
          },
          hint: 'Current status of the card.' },
        { name: 'gateway', control_type: 'select',
          pick_list: 'payment_gateway_list',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'gateway', control_type: 'text',
            type: 'string',
            label: 'Card gateway',
            toggle_hint: 'Use custom value',
            hint: 'Current status of the card. e.g. chargebee for ' \
                  'Chargebee test gateway.'
          },
          hint: 'Current status of the card.' },
        { name: 'gateway_account_id',
          hint: 'Gateway account in which payment source is stored.' },
        { name: 'ref_tx_id', label: 'Reference transaction ID' },
        { name: 'first_name',
          hint: "Cardholder's first name." },
        { name: 'last_name',
          hint: "Cardholder's last name." },
        { name: 'iin', label: 'Issuer Identification Number' },
        { name: 'last4', label: 'Last four digits of the card number' },
        { name: 'card_type', control_type: 'select',
          pick_list: 'card_type_list',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'card_type', control_type: 'text',
            type: 'string',
            label: 'Card type',
            toggle_hint: 'Use custom value',
            hint: 'Card type. e.g. visa for Visa card.'
          },
          hint: 'Current status of the card.' },
        { name: 'funding_type', control_type: 'select',
          pick_list: 'funding_type_list',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'funding_type', control_type: 'text',
            type: 'string',
            label: 'Funding type',
            toggle_hint: 'Use custom value',
            hint: 'Card Funding type. e.g. credit for Credit card.'
          },
          hint: 'Current status of the card.' },
        { name: 'expiry_month', type: 'integer', label: 'Card expiry month',
          optional: false, hint: 'Card expiry month.' },
        { name: 'expiry_year', type: 'integer', label: 'Card expiry year',
          optional: false, hint: 'Card expiry year.' },
        { name: 'issuing_country', hint: '2-letter(alpha2) ISO country code.' },
        { name: 'billing_addr1', label: 'Billing address line 1',
          hint: 'Address line 1, as available in card billing address.' },
        { name: 'billing_addr2', label: 'Billing address line 2',
          hint: 'Address line 2, as available in card billing address.' },
        { name: 'billing_city',
          hint: 'City, as available in card billing address.' },
        { name: 'billing_state_code',
          hint: 'The ISO 3166-2 state/province code without the country ' \
                'prefix. Currently supported for USA, Canada and India' },
        { name: 'billing_state', hint: 'The state/province name.' },
        { name: 'billing_country',
          hint: '2-letter, ISO 3166 alpha-2 country code.' },
        { name: 'billing_zip',
          hint: 'Postal or Zip code, as available in card billing address.' },
        { name: 'created_at', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
        { name: 'resource_version' },
        { name: 'updated_at', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
        { name: 'ip_address' },
        { name: 'powered_by', control_type: 'select',
          pick_list: 'powered_by_list',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'powered_by', control_type: 'text',
            type: 'string',
            label: 'Powered by',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values: ideal, sofort, bancontact, giropay, ' \
                  'not_applicable'
          } },
        { name: 'customer_id' },
        { name: 'masked_number' }
      ]
    end,
    subscription_schema: lambda do |input|
      fields = [
        { name: 'id', label: 'Subscription ID', sticky: true,
          hint: 'A unique and immutable identifier for the subscription. ' \
                'If not provided, it is autogenerated.' },
        { name: 'plan_id', sticky: true,
          hint: 'Identifier of the plan for this subscription.' },
        { name: 'currency_code' },
        { name: 'plan_quantity', type: 'integer', control_type: 'integer',
          convert_output: 'integer_conversion',
          convert_input: 'integer_conversion',
          hint: 'Plan quantity for this subscription.' },
        { name: 'plan_unit_price', type: 'number', control_type: 'number',
          hint: 'Amount that will override the Plans default price.' },
        { name: 'setup_fee', type: 'number', control_type: 'number',
          hint: 'Amount that will override the default setup fee.' },
        { name: 'billing_period', type: 'integer', control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'billing_period_unit' },
        { name: 'start_date', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp',
          hint: 'The date/time at which the subscription is to start or has started. ' \
                'If not provided, the subscription starts immediately. If ' \
                'set to a value in the past then that date/time should not be ' \
                'more than a plan billing period into the past.' },
        { name: 'trial_end', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp',
          hint: 'The time at which the trial ends for this subscription. Can be ' \
                "specified to override the default trial period.If '0' is passed, " \
                'the subscription will be activated immediately.' },
        { name: 'remaining_billing_cycles', type: 'integer',
          control_type: 'integer', convert_output: 'integer_conversion' },
        { name: 'po_number', label: 'Purchase order number',
          hint: 'Purchase order number for this subscription.' },
        { name: 'coupon_ids', label: 'Coupon IDs', type: 'array', of: 'string',
          hint: 'List of coupons to be applied to this subscription. ' \
                'You can provide coupon ids or coupon codes.' },
        { name: 'billing_cycles', type: 'integer', control_type: 'integer',
          convert_input: 'integer_conversion',
          convert_output: 'integer_conversion',
          hint: 'Number of cycles(plan interval) this subscription should be charged. ' \
                'After the billing cycles exhausted, the subscription will be cancelled.' },
        { name: 'auto_collection', type: 'string', sticky: true,
          control_type: 'select', pick_list: 'auto_collection',
          hint: 'Defines whether payments need to be collected automatically for this ' \
                "subscription. Overrides customer's auto-collection property.",
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'auto_collection',
            label: 'Auto collection',
            optional: true,
            sticky: true,
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: 'Defines whether payments need to be collected automatically for ' \
                  'this subscription. Overrides customers auto-collection ' \
                  "property. Allowed values are 'on', 'off'"
          } },
        { name: 'terms_to_charge', type: 'integer', control_type: 'integer',
          convert_input: 'integer_conversion',
          convert_output: 'integer_conversion',
          hint: 'The number of subscription billing cycles (including the first one) ' \
                'to invoice in advance.' },
        { name: 'billing_alignment_mode', type: 'string', sticky: true,
          control_type: 'select', pick_list: 'billing_alignment_mode',
          hint: 'Override the billing alignment mode for Calendar Billing. ' \
                'Only applicable when using Calendar Billing. The default value ' \
                'is that which has been configured for the site.',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'billing_alignment_mode',
            label: 'Billing alignment mode',
            optional: true,
            sticky: true,
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: 'Override the billing alignment mode for Calendar Billing. ' \
                  'Only applicable when using Calendar Billing. The default ' \
                  'value is that which has been configured for the site.' \
                  "Allowed values are 'immediate', 'delayed'"
          } },
        { name: 'mandatory_addons_to_remove', type: 'array', of: 'string',
          hint: 'List of addons IDs that are mandatory to the plan and has to ' \
                'be removed from the subscription.' },
        { name: 'customer_id' },
        { name: 'channel' },
        { name: 'object' },
        { name: 'plan_amount', type: 'number', control_type: 'number' },
        { name: 'plan_free_quantity', type: 'integer', control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'status' },
        { name: 'trial_start', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
        { name: 'current_term_start', type: 'date_time',
          control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
        { name: 'current_term_end', type: 'date_time',
          control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
        { name: 'next_billing_at', type: 'date_time',
          control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
        { name: 'created_at', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
        { name: 'started_at', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
        { name: 'activated_at', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
        { name: 'gift_id' },
        { name: 'contract_term_billing_cycle_on_renewal',
          type: 'integer', control_type: 'integer',
          convert_input: 'integer_conversion',
          convert_output: 'integer_conversion',
          hint: 'Number of billing cycles the new contract term should run for, on ' \
                'contract renewal. The default value is the same as billing_cycles or ' \
                'a custom value depending on the site configuration.' },
        { name: 'pause_date', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
        { name: 'resume_date', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
        { name: 'cancelled_at', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
        { name: 'cancel_reason' },
        { name: 'trial_end_action', control_type: 'select',
          pick_list: 'trial_end_action_list',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'trial_end_action', label: 'Trial end action',
            optional: true,
            type: 'string', control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: "Allowed values are 'site_default', 'plan_default', " \
                  "'activate_subscription' and 'cancel_subscription'"
          } },
        { name: 'cancel_schedule_created_at', type: 'date_time',
          control_type: 'date_time',
          convert_input: 'render_epoch_time',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'changes_scheduled_at', type: 'date_time',
          control_type: 'date_time',
          convert_input: 'render_epoch_time',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'affiliate_token' },
        { name: 'created_from_ip', label: 'Created from IP' },
        { name: 'resource_version', type: 'number', control_type: 'number' },
        { name: 'updated_at', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
        { name: 'has_scheduled_advance_invoices', type: 'boolean',
          control_type: 'checkbox', convert_output: 'boolean_conversion' },
        { name: 'has_scheduled_changes', type: 'boolean',
          control_type: 'checkbox', convert_output: 'boolean_conversion' },
        { name: 'payment_source_id',
          hint: 'ID of the payment source to be attached to this subscription.' },
        { name: 'override_relationship',
          type: 'boolean', control_type: 'checkbox',
          convert_input: 'boolean_conversion',
          convert_output: 'boolean_conversion',
          hint: 'If true, ignores the hierarchy relationship and uses customer as ' \
                'payment and invoice owner.',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'override_relationship', label: 'Override relationship',
            optional: true, sticky: true,
            type: 'string', control_type: 'text',
            convert_input: 'boolean_conversion',
            convert_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            hint: 'If true, ignores the hierarchy relationship and uses customer as ' \
                  'payment and invoice owner. Allowed values are: true, false.'
          } },
        { name: 'invoice_immediately',
          type: 'boolean', control_type: 'checkbox',
          convert_input: 'boolean_conversion',
          convert_output: 'boolean_conversion',
          hint: 'If there are charges raised immediately for the subscription, this ' \
                'parameter specifies whether those charges are to be invoiced ' \
                'immediately or added to unbilled charges. The default value is ' \
                'as per the site settings.',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'invoice_immediately', label: 'Invoice immediately',
            optional: true, sticky: true,
            type: 'string', control_type: 'text',
            convert_input: 'boolean_conversion',
            convert_output: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            hint: 'If there are charges raised immediately for the subscription, ' \
                  'this parameter specifies whether those charges are to be invoiced ' \
                  'immediately or added to unbilled charges. The default value is as ' \
                  'per the site settings. Allowed values are: true, false.'
          } },
        { name: 'plan_free_quantity_in_decimal' },
        { name: 'plan_quantity_in_decimal', sticky: true,
          hint: 'The decimal representation of the quantity of the plan purchased. ' \
                'Can be provided for quantity-based plans and only when ' \
                'multi-decimal pricing is enabled.' },
        { name: 'plan_unit_price_in_decimal',
          hint: 'When price overriding is enabled for the site, the price or ' \
                'per-unit price of the plan can be set here. The value set for ' \
                'the plan is used by default. Provide the value as a decimal ' \
                'string in major units of the currency. Can be provided ' \
                'only when multi-decimal pricing is   enabled.' },
        { name: 'plan_amount_in_decimal' },
        { name: 'offline_payment_method', type: 'string', sticky: true,
          control_type: 'select', pick_list: 'offline_payment_method_list',
          hint: 'The preferred offline payment method for the subscription.',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'offline_payment_method',
            label: 'Offline payment method',
            optional: true,
            sticky: true,
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: 'The preferred offline payment method for the subscription.' \
                  "Allowed values are 'cash', 'check', 'bank_transfer', 'ach_credit', 'sepa_credit'"
          } },
        { name: 'due_invoices_count', type: 'integer', control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'due_since', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
        { name: 'total_dues', type: 'number', control_type: 'number' },
        { name: 'mrr', label: 'Monthly recurring revenue',
          type: 'number', control_type: 'number' },
        { name: 'exchange_rate', type: 'number', control_type: 'number' },
        { name: 'base_currency_code' },
        { name: 'invoice_notes',
          hint: 'Notes to be added to any invoice for this subscription.' },
        { name: 'deleted', type: 'boolean', control_type: 'checkbox',
          convert_output: 'boolean_conversion' },
        { name: 'cancel_reason_code' },
        { name: 'free_period', type: 'integer', control_type: 'integer',
          convert_input: 'integer_conversion',
          convert_output: 'integer_conversion' },
        { name: 'free_period_unit', type: 'string', sticky: true,
          control_type: 'select', pick_list: 'period_unit',
          hint: 'The unit of time in multiples of which the free_period parameter ' \
                'is expressed. The value must be equal to or lower than the ' \
                'period_unit attribute of the plan chosen.',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'free_period_unit',
            label: 'Free period unit',
            optional: true,
            sticky: true,
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: "Allowed values are 'day', 'week', 'month', 'year'"
          } },
        { name: 'create_pending_invoices',
          type: 'boolean',
          control_type: 'checkbox',
          convert_output: 'boolean_conversion',
          toggle_hint: 'Select from list',
          convert_input: 'boolean_conversion',
          toggle_field: {
            name: 'create_pending_invoices',
            label: 'Create pending invoices',
            type: 'string',
            control_type: 'text',
            optional: true,
            sticky: true,
            convert_output: 'boolean_conversion',
            convert_input: 'boolean_conversion',
            hint: 'Accepted values are true or false',
            toggle_hint: 'Use custom value'
          } },
        { name: 'auto_close_invoices',
          type: 'boolean',
          control_type: 'checkbox',
          convert_output: 'boolean_conversion',
          toggle_hint: 'Select from list',
          convert_input: 'boolean_conversion',
          toggle_field: {
            name: 'auto_close_invoices',
            label: 'Auto close invoices',
            type: 'string',
            control_type: 'text',
            optional: true,
            sticky: true,
            convert_output: 'boolean_conversion',
            convert_input: 'boolean_conversion',
            hint: 'Accepted values are true or false',
            toggle_hint: 'Use custom value'
          } },
        { name: 'subscription_items', type: 'array', of: 'object',
          properties: [
            { name: 'item_price_id' },
            { name: 'item_type' },
            { name: 'quantity', type: 'integer', control_type: 'integer',
              convert_output: 'integer_conversion',
              convert_input: 'integer_conversion' },
            { name: 'quantity_in_decimal' },
            { name: 'free_quantity_in_decimal' },
            { name: 'free_quantity', type: 'integer', control_type: 'number',
              convert_output: 'integer_conversion',
              convert_input: 'integer_conversion' },
            { name: 'amount_in_decimal' },
            { name: 'amount', type: 'number', control_type: 'number' },
            { name: 'unit_price', type: 'integer', control_type: 'number',
              convert_output: 'integer_conversion',
              convert_input: 'integer_conversion' },
            { name: 'unit_price_in_decimal' },
            { name: 'billing_cycles', type: 'integer', control_type: 'integer',
              convert_output: 'integer_conversion',
              convert_input: 'integer_conversion' },
            { name: 'trial_end', type: 'date_time', control_type: 'date_time',
              convert_output: 'render_iso8601_timestamp',
              convert_input: 'render_epoch_time' },
            { name: 'service_period_days',
              type: 'integer',
              control_type: 'integer',
              convert_output: 'integer_conversion',
              convert_input: 'integer_conversion' },
            { name: 'charge_on_event', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'on_event',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'charge_on_event',
                label: 'Charge on event',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'subscription_creation', 'subscription_trial_start', " \
                      "'plan_activation', 'subscription_activation', 'contract_termination'"
              } },
            { name: 'charge_once',
              type: 'boolean',
              control_type: 'checkbox',
              convert_output: 'boolean_conversion',
              toggle_hint: 'Select from list',
              convert_input: 'boolean_conversion',
              toggle_field: { name: 'charge_once',
                              label: 'Charge once',
                              type: 'string',
                              control_type: 'text',
                              optional: true,
                              sticky: true,
                              convert_output: 'boolean_conversion',
                              convert_input: 'boolean_conversion',
                              hint: 'Accepted values are true or false',
                              toggle_hint: 'Use custom value' } },
            { name: 'charge_on_option', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'charge_on',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'charge_on_option',
                label: 'Charge on option',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'immediately', 'on_event'"
              } }
          ] },
        { name: 'item_tiers', type: 'array', of: 'object',
          properties: [
            { name: 'item_price_id' },
            { name: 'starting_unit',
              type: 'integer',
              control_type: 'integer',
              convert_output: 'integer_conversion',
              convert_input: 'integer_conversion' },
            { name: 'ending_unit',
              type: 'integer',
              control_type: 'integer',
              convert_output: 'integer_conversion',
              convert_input: 'integer_conversion' },
            { name: 'price',
              type: 'integer',
              control_type: 'number',
              convert_output: 'integer_conversion',
              convert_input: 'integer_conversion' },
            { name: 'starting_unit_in_decimal' },
            { name: 'ending_unit_in_decimal' },
            { name: 'price_in_decimal' }
          ] },
        { name: 'charged_items', type: 'array', of: 'object',
          properties: [
            { name: 'item_price_id' },
            { name: 'last_charged_at', type: 'date_time',
              control_type: 'date_time',
              convert_input: 'render_epoch_time',
              convert_output: 'render_iso8601_timestamp' }
          ] },
        { name: 'addons', type: 'array', of: 'object',
          properties: [
            { name: 'id' },
            { name: 'quantity', type: 'integer', control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'unit_price', type: 'number', control_type: 'number' },
            { name: 'amount', type: 'number', control_type: 'number' },
            { name: 'trial_end', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
            { name: 'remaining_billing_cycles', type: 'integer',
              control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'quantity_in_decimal' },
            { name: 'unit_price_in_decimal' },
            { name: 'amount_in_decimal' }
          ] },
        { name: 'event_based_addons', type: 'array', of: 'object',
          properties: [
            { name: 'id' },
            { name: 'quantity', type: 'integer', control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'unit_price', type: 'number', control_type: 'number' },
            { name: 'on_event', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'on_event',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'on_event',
                label: 'On event',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'subscription_creation', 'subscription_trial_start', " \
                      "'plan_activation', 'subscription_activation', 'contract_termination'"
              } },
            { name: 'charge_once',
              type: 'boolean', control_type: 'checkbox',
              convert_input: 'boolean_conversion',
              toggle_hint: 'Select from list',
              sticky: true,
              toggle_field: {
                name: 'charge_once', label: 'Charge once',
                optional: true, sticky: true,
                type: 'string', control_type: 'text',
                convert_input: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true, false.'
              } },
            { name: 'quantity_in_decimal' },
            { name: 'unit_price_in_decimal' },
            { name: 'service_period_in_days', type: 'integer',
              control_type: 'integer',
              convert_input: 'integer_conversion',
              convert_output: 'integer_conversion',
              hint: 'Defines service period of the addon in days ' \
                    'from the day of charge.' },
            { name: 'charge_on', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'charge_on',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'charge_on',
                label: 'Charge on',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'immediately', 'on_event'"
              } },
            { name: 'object' }
          ] },
        { name: 'charged_event_based_addons', type: 'array', of: 'object',
          properties: [
            { name: 'id' },
            { name: 'last_charged_at', type: 'date_time',
              control_type: 'date_time',
              convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' }
          ] },
        { name: 'coupons', type: 'array', of: 'object',
          properties: [
            { name: 'coupon_id' },
            { name: 'apply_till', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
            { name: 'applied_count', type: 'integer', control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'coupon_code' }
          ] },
        { name: 'shipping_address', type: 'object',
          properties: [
            { name: 'first_name' },
            { name: 'last_name' },
            { name: 'email' },
            { name: 'company' },
            { name: 'phone' },
            { name: 'line1', label: 'Address line 1' },
            { name: 'line2', label: 'Address line 2' },
            { name: 'line3', label: 'Address line 3' },
            { name: 'city' },
            { name: 'state_code',
              hint: 'The ISO 3166-2 state/province code without the country prefix. ' \
                    'Currently supported for USA, Canada and India. For instance, for ' \
                    'Arizona (USA), set state_code as AZ (not US-AZ). For Tamil Nadu ' \
                    '(India), set as TN (not IN-TN). For British Columbia (Canada), ' \
                    'set as BC (not CA-BC).' },
            { name: 'state',
              hint: 'The state/province name. Is set by Chargebee automatically for ' \
                    'US, Canada and India If state_code is provided.' },
            { name: 'country', label: 'Country code',
              hint: 'ISO 3166 alpha-2 country code.' },
            { name: 'zip' },
            { name: 'validation_status', control_type: 'select',
              pick_list: 'validation_status_list',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'validation_status', control_type: 'text',
                type: 'string',
                label: 'Customer type',
                optional: true,
                toggle_hint: 'Use custom value',
                hint: 'Allowed vaalues are: not_validated, valid, partially_valid, invalid'
              },
              hint: 'The address verification status.' }
          ] },
        { name: 'payment_intent', type: 'object',
          properties: [
            { name: 'id', label: 'Payment intent ID',
              hint: 'Payment intent ID generated by Chargebee.js' },
            { name: 'gateway_account_id',
              hint: 'Gateway account used for performing the 3DS flow.' },
            { name: 'gw_token', label: 'Gateway token',
              hint: 'Identifier for 3DS transaction/verification object at the gateway.' },
            { name: 'reference_id',
              hint: 'Identifier for Braintree permanent token. Applicable when you are ' \
                    'using Braintree APIs for completing the 3DS flow.' },
            { name: 'additional_info', label: 'Additional information',
              hint: 'Pass a stringified JSON. For E.g: click <a href=' \
                "'https://apidocs.chargebee.com/docs/api/payment_parameters" \
                "#payment_intent_additonal_info_sample'>" \
                'here<a> to see sample json.' }
          ] },
        { name: 'referral_info', type: 'object',
          properties: [
            { name: 'referral_code' },
            { name: 'coupon_code' },
            { name: 'referrer_id' },
            { name: 'external_reference_id' },
            { name: 'reward_status' },
            { name: 'referral_system' },
            { name: 'account_id' },
            { name: 'campaign_id' },
            { name: 'external_campaign_id' },
            { name: 'friend_offer_type' },
            { name: 'referrer_reward_type' },
            { name: 'notify_referral_system' },
            { name: 'destination_url' },
            { name: 'post_purchase_widget_enabled', type: 'boolean',
              control_type: 'checkbox', convert_output: 'boolean_conversion' }
          ] },
        { name: 'contract_term', type: 'object',
          properties: [
            { name: 'id' },
            { name: 'status' },
            { name: 'contract_start', type: 'date_time',
              control_type: 'date_time',
              convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
            { name: 'contract_end', type: 'date_time',
              control_type: 'date_time',
              convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
            { name: 'billing_cycles', type: 'integer', control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'action_at_term_end' },
            { name: 'total_contract_value', type: 'number',
              control_type: 'number' },
            { name: 'cancellation_cutoff_period', type: 'integer',
              control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'created_at', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
            { name: 'subscription_id' },
            { name: 'remaining_billing_cycles', type: 'integer',
              control_type: 'integer',
              convert_output: 'integer_conversion' }
          ] }
      ]
      if input['schema_builder'].present?
        fields.concat([
                        { name: 'meta_data', type: 'object',
                          properties: parse_json(input['schema_builder']) }
                      ])
      else
        fields
      end
    end,
    customer_schema: lambda do |input|
      fields = [
        { name: 'id', label: 'Customer ID', sticky: true,
          hint: 'Maximum characters 50 characters' },
        { name: 'first_name', sticky: true,
          hint: 'Maximum length of the first name is 150 characters' },
        { name: 'last_name', sticky: true,
          hint: 'Maximum length of the first name is 150 characters' },
        { name: 'email', control_type: 'email', sticky: true,
          hint: 'Email of the customer. Configured email ' \
                'notifications will be sent to this email. Maxium length ' \
                'of the email is 70 characters' },
        { name: 'phone', control_type: 'phone', sticky: true,
          hint: 'Maximum length of the phone is ' \
            '50 characters ' },
        { name: 'card_status' },
        { name: 'company', sticky: true,
          hint: 'Name of the company, Maxium length of ' \
                'the company is 250 characters' },
        { name: 'vat_number', label: 'VAT/ Tax registration number',
          hint: 'Maximum length of the VAT/ Tax ' \
                'registration number is 20characters' },
        { name: 'auto_collection',
          control_type: 'select',
          pick_list: 'auto_collection_list',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'auto_collection',
            type: 'string',
            control_type: 'text',
            label: 'Auto collection',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are <b>on, off</b>'
          },
          hint: 'Whether payments needs to be ' \
                'collected automatically for this customer.' },
        { name: 'offline_payment_method',
          control_type: 'select',
          pick_list: 'offline_payment_method_list',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'offline_payment_method',
            type: 'string',
            control_type: 'text',
            label: 'Offline payment method',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'The preferred offline payment method for the customer' \
                  'E.g. no_preference, cash, check, bank_transfer, ' \
                  'ach_credit, sepa_credit'
          },
          hint: 'The preferred offline payment method for the customer' },
        { name: 'net_term_days',
          type: 'integer',
          control_type: 'integer',
          hint: 'The number of days within which the ' \
                'customer has to make payment' \
                ' for the invoice. Default value 0' },
        { name: 'vat_number_validated_time', label: 'VAT number validated time',
          type: 'date_time',
          control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp',
          hint: 'Returns the recent VAT number validation time in UTC' },
        { name: 'vat_number_status', label: 'VAT validation status',
          control_type: 'select',
          pick_list: 'vat_number_status_list',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'vat_number_status', label: 'VAT number status',
            type: 'string', control_type: 'text',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'This is only applicable if you have configured ' \
                  'EU or Australian taxes and the VAT number validation is ' \
                  'enabled. For UK, the value is always undetermined. Allowed ' \
                  'values: valid, invalid, not_validated, undetermined'
          } },
        {
          name: 'allow_direct_debit', type: 'boolean',
          control_type: 'checkbox',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'allow_direct_debit',
            type: 'string',
            control_type: 'text',
            optional: true,
            label: 'Allow direct debit',
            toggle_hint: 'Use custom value',
            hint: 'Whether the customer can pay via Direct Debit. ' \
                  'Allowed values are true, false'
          },
          hint: 'Whether the customer can pay via Direct Debit.'
        },
        {
          name: 'is_location_valid', type: 'boolean',
          control_type: 'checkbox',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'is_location_valid',
            type: 'string',
            control_type: 'text',
            optional: true,
            label: 'Is location valid',
            toggle_hint: 'Use custom value',
            hint: 'Customer location is validated based on IP address ' \
                  'and Card issuing country. If the location is valid, it ' \
                  'returns True. If not, it returns False. Applicable only for ' \
                  'EU, New Zealand and Australia. Allowed values are true, false'
          },
          hint: 'Customer location is validated based on IP address ' \
                'and Card issuing country. If the location is valid, it ' \
                'returns True. If not, it returns False. Applicable only for ' \
                'EU, New Zealand and Australia.'
        },
        { name: 'created_at', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp',
          hint: 'Timestamp indicating when this customer resource is created' },
        { name: 'created_from_ip', label: 'Created from IP',
          hint: 'The IP address of the customer. Used primarily for referral' \
            ' integrations and EU/UK VAT validation.' },
        { name: 'exemption_details',
          hint: 'Indicates the exemption information. You can customize ' \
                'customer exemption based on specific Location, Tax ' \
                'level (Federal, State, County and Local), Category of ' \
                'Tax or specific Tax Name. Refer' \
                "<a href='https://apidocs.chargebee.com/docs/api/customers" \
                "?prod_cat_ver=2#update_a_customer' target='_blank'></a>" },
        { name: 'taxability', control_type: 'select',
          pick_list: 'taxability_list',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'taxability', control_type: 'text',
            type: 'string',
            label: 'Taxability',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Specifies if the customer is liable for tax. Allowed ' \
              'values are: taxable, exempt'
          } },
        { name: 'entity_code', control_type: 'select',
          pick_list: 'entity_code_list',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'entity_code', control_type: 'text',
            type: 'string',
            label: 'Entity code',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'The exemption category of the customer, for USA and ' \
                  'Canada. Applicable if you use Chargebee\'s AvaTax for ' \
                  'Sales integration. For e.g. Federal government - a, ' \
                  'State government - b.'
          },
          hint: 'The exemption category of the customer, for USA and Canada. ' \
                'Applicable if you use Chargebee\'s AvaTax for Sales integration.' },
        { name: 'exempt_number',
          hint: 'Any string value that will cause the sale to be exempted. Use this if your' \
                ' finance team manually verifies and tracks exemption certificates. ' \
                'Applicable if you use Chargebee\'s AvaTax for Sales integration' },
        { name: 'resource_version', type: 'integer', control_type: 'integer',
          hint: 'Version number of this resource. Each update of this resource results in ' \
                'incremental change of this number. This attribute will be present only if the' \
                ' resource has been updated after 2016-09-28.' },
        { name: 'updated_at', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp',
          hint: 'This field will be present only if the resource has been' \
                ' updated after 2016-09-28.' },
        { name: 'locale',
          hint: 'Determines which region-specific language Chargebee ' \
                'uses to communicate with the customer' },
        { name: 'billing_date', type: 'integer', control_type: 'integer',
          hint: 'Minimum value 1, Maximum value 31.' },
        { name: 'billing_date_mode', control_type: 'select',
          pick_list: 'billing_date_mode_list',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'billing_date_mode', control_type: 'text',
            type: 'string',
            label: 'Billing date mode',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Indicates whether this customer\'s billing_date value is derived ' \
                  'as per configurations or its specifically set. Allowed values: ' \
                  'using_defaults, manually_set'
          },
          hint: 'Indicates whether this customer\'s billing_date value is derived ' \
                'as per configurations or its specifically set. Allowed ' \
                'values: using_defaults, manually_set' },
        { name: 'billing_day_of_week', control_type: 'select',
          pick_list: 'billing_day_of_week_list',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'billing_day_of_week', control_type: 'text',
            type: 'string',
            label: 'Billing day of week',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Applicable when calendar billing is enabled, e.g.' \
              ' <code>sunday</code> for Sunday'
          },
          hint: 'Applicable when calendar billing (with customer specific billing ' \
                'date support) is enabled' },
        { name: 'billing_day_of_week_mode', control_type: 'select',
          pick_list: 'billing_day_of_week_mode_list',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'billing_day_of_week_mode', control_type: 'text',
            type: 'string',
            label: 'Billing day of week mode',
            optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values: using_defaults, manually_set'
          },
          hint: 'Indicates whether this customer\'s billing_day_of_week value' \
                ' is derived as per configurations or its specifically set' },
        { name: 'pii_cleared', label: 'Personal information cleared',
          control_type: 'select',
          pick_list: 'pii_cleared_list',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'pii_cleared',
            control_type: 'text',
            type: 'string',
            optional: true,
            label: 'Personal information cleared',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values: active, scheduled_for_clear, cleared'
          },
          hint: 'Indicates whether this customer\'s personal information has been cleared' },
        {
          name: 'auto_close_invoices', type: 'boolean',
          control_type: 'checkbox',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'auto_close_invoices',
            type: 'string',
            control_type: 'text', optional: true,
            label: 'Auto close invoices',
            toggle_hint: 'Use custom value',
            hint: 'Override site setting for auto closing invoices for metered billing. ' \
              'Allowed values are true, false'
          },
          hint: 'Override site setting for auto closing invoices for metered billing.'
        },
        { name: 'fraud_flag', control_type: 'select',
          pick_list: 'customer_fraud_flag_list',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'fraud_flag', control_type: 'text',
            type: 'string',
            label: 'Fraud flag', optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values: safe, fraudulent'
          },
          hint: 'Indicates whether or not the customer has been identified as fraudulent.' },
        { name: 'primary_payment_source_id',
          hint: 'Maximum length of the primary payment source is 40 characters' },
        { name: 'backup_payment_source_id',
          hint: 'Maximum length of the backup payment source id is 40 characters' },
        { name: 'invoice_notes', control_type: 'text-area',
          hint: 'Maximum length of the invoice notes is 2000 characters' },
        { name: 'preferred_currency_code',
          hint: 'The currency code of the customer\s preferred currency (ISO 4217 format)' \
                '. Applicable if the Multicurrency feature is enabled. Maximum ' \
                'length is 3 characters.' },
        { name: 'promotional_credits', hint: 'In cents, minimum is 0.' },
        { name: 'unbilled_charges', hint: 'In cents, minimum is 0.' },
        { name: 'refundable_credits', hint: 'In cents, minimum is 0.' },
        { name: 'excess_payments', hint: 'In cents, minimum is 0.' },
        {
          name: 'deleted', type: 'boolean',
          control_type: 'checkbox',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'deleted',
            type: 'string',
            control_type: 'text', optional: true,
            label: 'Deleted',
            toggle_hint: 'Use custom value',
            hint: 'Indicates that this resource has been deleted. Allowed values' \
              ' are true, false'
          },
          hint: 'Indicates that this resource has been deleted.'
        },
        {
          name: 'registered_for_gst', type: 'boolean',
          label: 'Registered for GST',
          control_type: 'checkbox',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'registered_for_gst',
            type: 'string',
            control_type: 'text', optional: true,
            label: 'Registered for GST',
            toggle_hint: 'Use custom value',
            hint: 'Confirms that a customer is registered under GST.' \
                  ' If set to true then the Reverse Charge Mechanism is ' \
                  'applicable. Allowed values are true, false'
          },
          hint: 'Confirms that a customer is registered under GST. If set to true then ' \
                'the Reverse Charge Mechanism is applicable.'
        },
        {
          name: 'consolidated_invoicing', type: 'boolean',
          control_type: 'checkbox',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'consolidated_invoicing',
            type: 'string',
            control_type: 'text', optional: true,
            label: 'Consolidated Invoicing',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are true, false'
          }
        },
        { name: 'customer_type', control_type: 'select',
          pick_list: 'customer_type_list',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'customer_type', control_type: 'text',
            type: 'string',
            label: 'Customer type', optional: true,
            toggle_hint: 'Use custom value',
            hint: 'This is applicable only if you use Chargebee’s AvaTax ' \
                  'for Communications integration. Allowed values are: residential, business,' \
                  'senior_citizen, industrial'
          },
          hint: 'Indicates the type of the customer. This is applicable only if you use' \
                ' Chargebee’s AvaTax for Communications integration.' },
        {
          name: 'business_customer_without_vat_number', type: 'boolean',
          control_type: 'checkbox',
          label: 'Business customer without VAT number',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'business_customer_without_vat_number',
            type: 'string',
            control_type: 'text', optional: true,
            label: 'Business customer without VAT number',
            toggle_hint: 'Use custom value',
            hint: 'Confirms that a customer is a valid business without an EU/UK VAT number. ' \
                  'Allowed values are true, false'
          },
          hint: 'Confirms that a customer is a valid business without an EU/UK VAT number'
        },
        { name: 'client_profile_id',
          hint: 'Maximum length of the client profile id is 50 characters' },
        {
          name: 'use_default_hierarchy_settings', type: 'boolean',
          control_type: 'checkbox',
          label: 'Use default hierarchy settings',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'use_default_hierarchy_settings',
            type: 'string',
            control_type: 'text', optional: true,
            label: 'Use default hierarchy settings',
            toggle_hint: 'Use custom value',
            hint: 'Confirms that a customer is a valid business without an EU/UK VAT number. ' \
                  'Allowed values are true, false'
          },
          hint: 'Confirms that a customer is a valid business without an EU/UK VAT number'
        },
        { name: 'entity_identifier_scheme',
          hint: 'The Peppol BIS scheme associated with the ' \
                'vat_number of the customer. Refer '\
                "<a href='https://apidocs.chargebee.com/docs/api" \
                '/customers?prod_cat_ver=2&lang=curl#create_a_' \
                "customer' target='_blank'>API documentation</a> " \
                'for more information.' },
        { name: 'entity_identifier_standard',
          hint: 'The standard used for specifying the entity_' \
                'identifier_scheme. Currently only iso6523-actorid-' \
                'upis is supported and is used by default ' \
                'when not provided. Refer '\
                "<a href='https://apidocs.chargebee.com/docs/api" \
                '/customers?prod_cat_ver=2&lang=curl#create_a_' \
                "customer' target='_blank'>API documentation</a> " \
                'for more information.' },
        { name: 'is_einvoice_enabled', label: 'Is E-invoice enabled',
          type: 'boolean', control_type: 'checkbox',
          convert_input: 'boolean_conversion',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'is_einvoice_enabled', label: 'Is E-invoice enabled',
            type: 'string', control_type: 'text',
            optional: true,
            convert_input: 'boolean_conversion',
            hint: 'Accepted values are true or false',
            toggle_hint: 'Use custom value'
          } },
        { name: 'vat_number_prefix', label: 'VAT number prefix' },
        { name: 'billing_address', type: 'object',
          properties: call('business_address_schema', '') },
        { name: 'referral_urls', label: 'Referral URLs',
          type: 'array', of: 'object',
          properties: call('referral_url_schema', '') },
        { name: 'contacts', type: 'array', of: 'object',
          properties: call('contact_schema', '') },
        { name: 'entity_identifiers', type: 'array', of: 'object',
          properties: [
            { name: 'id',
              hint: 'The unique id for the entity_identifier in ' \
                    'Chargebee. When not provided, it is autogenerated.' },
            { name: 'schema',
              hint: 'The Peppol BIS scheme associated with the ' \
                    'vat_number of the customer. Refer' \
                    "<a href='https://apidocs.chargebee.com/docs/api" \
                    "/customers?prod_cat_ver=2#create_a_customer', " \
                    "target='_blank'>API documentation</a> for " \
                    'more information.' },
            { name: 'value',
              hint: 'The value of the entity_identifier. This ' \
                    'identifies the customer entity on the Peppol ' \
                    'network. For example: 10101010-STO-10.' },
            { name: 'standard',
              hint: 'The standard used for specifying the entity_' \
                    'identifier scheme. Currently, only iso6523-' \
                    'actorid-upis is supported and is used by ' \
                    'default when not provided.' }
          ] },
        { name: 'payment_method', type: 'object',
          properties: call('payment_method_schema', '').ignored('gateway') },
        { name: 'balances', type: 'array', of: 'object',
          properties: call('balance_schema', '') },
        { name: 'relationship', type: 'object',
          properties: call('relationship_schema', '') },
        { name: 'parent_account_access', type: 'object',
          properties: call('parent_account_access_schema', '') },
        { name: 'child_account_access', type: 'object',
          properties: call('child_account_access_schema', '') }
      ]
      if input['schema_builder'].present?
        fields.concat([
                        { name: 'meta_data', type: 'object',
                          properties: parse_json(input['schema_builder']) }
                      ])
      else
        fields
      end
    end,
    payment_source_schema: lambda do
      [
        { name: 'id' },
        { name: 'customer_id' },
        { name: 'deleted',
          type: 'boolean',
          control_type: 'checkbox',
          convert_output: 'boolean_conversion' },
        { name: 'gateway' },
        { name: 'gateway_account_id' },
        { name: 'issuing_country' },
        { name: 'object' },
        { name: 'reference_id' },
        { name: 'resource_version',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'status' },
        { name: 'ip_address' },
        { name: 'type' },
        { name: 'created_at',
          type: 'date_time',
          control_type: 'date_time',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'updated_at',
          type: 'date_time',
          control_type: 'date_time',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'card',
          type: 'object',
          properties: [
            { name: 'brand' },
            { name: 'expiry_month',
              type: 'integer',
              control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'expiry_year',
              type: 'integer',
              control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'first_name' },
            { name: 'funding_type' },
            { name: 'iin' },
            { name: 'last4' },
            { name: 'last_name' },
            { name: 'masked_number' },
            { name: 'object' }
          ] },
        { name: 'bank_account',
          type: 'object',
          properties: [
            { name: 'last4' },
            { name: 'name_on_account' },
            { name: 'bank_name' },
            { name: 'mandate_id' },
            { name: 'account_type' },
            { name: 'echeck_type' },
            { name: 'account_holder_type' }
          ] },
        { name: 'amazon_payment',
          type: 'object',
          properties: [
            { name: 'email' },
            { name: 'agreement_id' }
          ] },
        { name: 'paypal',
          type: 'object',
          properties: [
            { name: 'email' },
            { name: 'agreement_id' }
          ] }
      ]
    end,
    hierarchy_get_output: lambda do |_input|
      [
        { name: 'hierarchies', type: 'array', of: 'object',
          properties: [
            { name: 'customer_id' },
            { name: 'object' },
            { name: 'parent_id' },
            { name: 'payment_owner_id' },
            { name: 'invoice_owner_id' },
            { name: 'children_ids', label: 'Children IDs',
              type: 'array', of: 'string' }
          ] }
      ]
    end,
    hierarchy_get_input: lambda do
      [
        { name: 'customer_id', optional: false },
        { name: 'hierarchy_operation_type', type: 'string', sticky: true,
          control_type: 'select', pick_list: 'hierarchy_operation_type',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'hierarchy_operation_type',
            label: 'Hierarchy operation type',
            optional: true,
            sticky: true,
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: "Allowed values are 'complete_hierarchy', 'subordinates', 'path_to_root'"
          } }
      ]
    end,
    item_schema: lambda do |input|
      fields = [
        { name: 'id' },
        { name: 'name' },
        { name: 'type' },
        { name: 'description' },
        { name: 'is_giftable',
          type: 'boolean',
          control_type: 'checkbox',
          convert_output: 'boolean_conversion' },
        { name: 'is_shippable',
          type: 'boolean',
          control_type: 'checkbox',
          convert_output: 'boolean_conversion' },
        { name: 'item_applicability' },
        { name: 'item_family_id' },
        { name: 'enabled_for_checkout',
          type: 'boolean',
          control_type: 'checkbox',
          convert_output: 'boolean_conversion' },
        { name: 'enabled_in_portal',
          type: 'boolean',
          control_type: 'checkbox',
          convert_output: 'boolean_conversion' },
        { name: 'included_in_mrr', label: 'Included in MRR',
          type: 'boolean',
          control_type: 'checkbox',
          convert_output: 'boolean_conversion' },
        { name: 'object' },
        { name: 'resource_version',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'status' },
        { name: 'updated_at',
          type: 'date_time',
          control_type: 'date_time',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'archived_at',
          type: 'date_time',
          control_type: 'date_time',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'redirect_url' },
        { name: 'gift_claim_redirect_url' },
        { name: 'unit' },
        { name: 'metered',
          type: 'boolean',
          control_type: 'checkbox',
          convert_output: 'boolean_conversion' },
        { name: 'usage_calculation' },
        { name: 'applicable_items', type: 'array', of: 'object',
          properties: [
            { name: 'id' }
          ] }
      ]
      if input['schema_builder'].present?
        fields.concat([
                        { name: 'metadata', type: 'object',
                          properties: parse_json(input['schema_builder']) }
                      ])
      else
        fields
      end
    end,
    attached_item_schema: lambda do |_input|
      [
        { name: 'id' },
        { name: 'item_id' },
        { name: 'charge_on_event' },
        { name: 'charge_once',
          type: 'boolean',
          control_type: 'checkbox',
          convert_output: 'boolean_conversion' },
        { name: 'type' },
        { name: 'object' },
        { name: 'parent_item_id' },
        { name: 'quantity',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'billing_cycles',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'quantity_in_decimal' },
        { name: 'resource_version',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'status' },
        { name: 'created_at',
          type: 'date_time',
          control_type: 'date_time',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'updated_at',
          type: 'date_time',
          control_type: 'date_time',
          convert_output: 'render_iso8601_timestamp' }
      ]
    end,
    item_price_schema: lambda do |input|
      fields = [
        { name: 'id' },
        { name: 'name' },
        { name: 'item_family_id' },
        { name: 'status' },
        { name: 'currency_code' },
        { name: 'external_name' },
        { name: 'description' },
        { name: 'free_quantity',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'is_taxable',
          type: 'boolean',
          control_type: 'checkbox',
          convert_output: 'boolean_conversion' },
        { name: 'item_id' },
        { name: 'item_type' },
        { name: 'object' },
        { name: 'period',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'period_unit' },
        { name: 'trial_period_unit' },
        { name: 'shipping_period',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'billing_cycles',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'invoice_notes' },
        { name: 'show_description_in_quotes',
          type: 'boolean',
          control_type: 'checkbox',
          convert_output: 'boolean_conversion' },
        { name: 'show_description_in_invoices',
          type: 'boolean',
          control_type: 'checkbox',
          convert_output: 'boolean_conversion' },
        { name: 'shipping_period_unit' },
        { name: 'trial_period',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'price',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'pricing_model' },
        { name: 'price_in_decimal' },
        { name: 'trial_end_action' },
        { name: 'free_quantity_in_decimal' },
        { name: 'resource_version',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'created_at',
          type: 'date_time',
          control_type: 'date_time',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'updated_at',
          type: 'date_time',
          control_type: 'date_time',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'archived_at',
          type: 'date_time',
          control_type: 'date_time',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'tiers', type: 'array', of: 'object',
          properties: [
            { name: 'starting_unit', type: 'integer', control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'ending_unit', type: 'integer', control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'price', type: 'number', control_type: 'number' }
          ] },
        { name: 'tax_detail', type: 'object',
          properties: [
            { name: 'tax_profile_id' },
            { name: 'avalara_sale_type' },
            { name: 'avalara_transaction_type', type: 'integer', control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'avalara_service_type', type: 'integer', control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'hsn_code', label: 'HSN code' },
            { name: 'avalara_tax_code' },
            { name: 'taxjar_product_code' }
          ] },
        { name: 'accounting_detail', type: 'object',
          properties: [
            { name: 'sku', label: 'SKU' },
            { name: 'accounting_code' },
            { name: 'accounting_category1' },
            { name: 'accounting_category2' },
            { name: 'accounting_category3' },
            { name: 'accounting_category4' }
          ] }
      ]
      if input['schema_builder'].present?
        fields.concat([
                        { name: 'metadata', type: 'object',
                          properties: parse_json(input['schema_builder']) }
                      ])
      else
        fields
      end
    end,
    item_family_schema: lambda do |_input|
      [
        { name: 'id' },
        { name: 'name' },
        { name: 'description' },
        { name: 'status' },
        { name: 'resource_version', type: 'number', control_type: 'number' },
        { name: 'updated_at', type: 'date_time', control_type: 'date_time',
          convert_output: 'render_iso8601_timestamp' }
      ]
    end,
    item_get_input: lambda do
      [
        { name: 'id', label: 'Item ID', optional: false },
        {
          name: 'schema_builder',
          extends_schema: true,
          control_type: 'schema-designer',
          label: 'Data fields',
          sticky: true,
          empty_schema_title: 'Describe all fields for your meta fields.',
          hint: 'A set of key-value pairs stored as additional information for ' \
                'the item. Describe all your metadata fields.',
          optional: true,
          sample_data_type: 'json' # json_input / xml
        }
      ]
    end,
    item_get_output: lambda do |input|
      call('item_schema', input)
    end,
    item_price_get_input: lambda do
      [
        { name: 'id', label: 'Item price ID', optional: false },
        {
          name: 'schema_builder',
          extends_schema: true,
          control_type: 'schema-designer',
          label: 'Data fields',
          sticky: true,
          empty_schema_title: 'Describe all fields for your meta fields.',
          hint: 'A set of key-value pairs stored as additional information for ' \
                'the item price. Describe all your metadata fields.',
          optional: true,
          sample_data_type: 'json' # json_input / xml
        }
      ]
    end,
    item_price_get_output: lambda do |input|
      call('item_price_schema', input)
    end,
    coupon_schema: lambda do |input|
      fields = [
        { name: 'id' },
        { name: 'name' },
        { name: 'invoice_name' },
        { name: 'discount_type' },
        { name: 'discount_percentage', type: 'number', control_type: 'number' },
        { name: 'discount_amount', type: 'number', control_type: 'number' },
        { name: 'currency_code' },
        { name: 'duration_type' },
        { name: 'plan_ids', label: 'Plan IDs', type: 'array', of: 'string' },
        { name: 'addon_ids', label: 'Addon IDs', type: 'array', of: 'string' },
        { name: 'duration_month', type: 'integer', control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'valid_till', type: 'datetime', control_type: 'datetime',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'max_redemptions', type: 'integer', control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'status' },
        { name: 'apply_on' },
        { name: 'apply_discount_on' },
        { name: 'plan_constraint' },
        { name: 'addon_constraint' },
        { name: 'period', type: 'integer', control_type: 'integer',
          convert_input: 'integer_conversion',
          convert_output: 'integer_conversion' },
        { name: 'period_unit' },
        { name: 'redemptions', type: 'integer', control_type: 'integer',
          convert_input: 'integer_conversion',
          convert_output: 'integer_conversion' },
        { name: 'created_at', type: 'datetime', control_type: 'datetime',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'archived_at', type: 'datetime', control_type: 'datetime',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'resource_version', type: 'number', control_type: 'number' },
        { name: 'updated_at', type: 'datetime', control_type: 'datetime',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'included_in_mrr', label: 'Included in MRR',
          type: 'boolean', control_type: 'checkbox',
          convert_output: 'boolean_conversion' },
        { name: 'redemption', type: 'integer', control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'invoice_notes' },
        { name: 'item_constraints', type: 'array', of: 'object',
          properties: [
            { name: 'item_type' },
            { name: 'constraint' },
            { name: 'item_price_ids', label: 'Item price IDs',
              type: 'array', of: 'string' }
          ] },
        { name: 'item_constraint_criteria', type: 'array', of: 'object',
          properties: [
            { name: 'item_type' },
            { name: 'currencies', type: 'array', of: 'string' },
            { name: 'item_family_ids', label: 'Item family IDs',
              type: 'array', of: 'string' },
            { name: 'item_price_periods', label: 'Item price periods',
              type: 'array', of: 'string' }
          ] }
      ]
      if input['schema_builder'].present?
        fields.concat([
                        { name: 'meta_data', type: 'object',
                          properties: parse_json(input['schema_builder']) }
                      ])
      else
        fields
      end
    end,
    coupon_set_schema: lambda do |_input|
      [
        { name: 'id' },
        { name: 'coupon_id' },
        { name: 'name' },
        { name: 'archived_count',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'object' },
        { name: 'redeemed_count',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'total_count',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' }
      ]
    end,
    order_schema: lambda do |_input|
      [
        { name: 'id' },
        { name: 'document_number' },
        { name: 'invoice_id' },
        { name: 'subscription_id' },
        { name: 'customer_id' },
        { name: 'status' },
        { name: 'payment_status' },
        { name: 'order_type' },
        { name: 'price_type' },
        { name: 'order_date', type: 'date_time', control_type: 'date_time',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'shipping_date', type: 'date_time', control_type: 'date_time',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'created_by' },
        { name: 'tax',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'amount_paid',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'amount_adjusted',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'refundable_credits_issued',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'refundable_credits',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'rounding_adjustement',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'paid_on', type: 'date_time', control_type: 'date_time',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'created_at', type: 'date_time', control_type: 'date_time',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'updated_at', type: 'date_time', control_type: 'date_time',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'cancellation_reason' },
        { name: 'reference_id' },
        { name: 'fulfillment_status' },
        { name: 'note' },
        { name: 'tracking_id' },
        { name: 'tracking_url' },
        { name: 'batch_id' },
        { name: 'shipment_carrier' },
        { name: 'invoice_round_off_amount', type: 'number',
          control_type: 'number' },
        { name: 'shipping_cut_off_date', type: 'date_time', control_type: 'date_time',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'status_update_at', type: 'date_time', control_type: 'date_time',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'delivered_at', type: 'date_time', control_type: 'date_time',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'shipped_at', type: 'date_time', control_type: 'date_time',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'cancelled_at', type: 'date_time', control_type: 'date_time',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'resent_status' },
        { name: 'is_resent',
          type: 'boolean',
          control_type: 'checkbox',
          convert_output: 'boolean_conversion' },
        { name: 'is_gifted', type: 'boolean', control_type: 'checkbox',
          convert_output: 'boolean_conversion' },
        { name: 'gift_note' },
        { name: 'gift_id' },
        { name: 'resend_reason' },
        { name: 'original_order_id' },
        { name: 'resource_version',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'deleted',
          type: 'boolean',
          control_type: 'checkbox',
          convert_output: 'boolean_conversion' },
        { name: 'object' },
        { name: 'discount',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'sub_total',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'order_line_items', type: 'array', of: 'object',
          properties: [
            { name: 'id' },
            { name: 'invoice_id' },
            { name: 'invoice_line_item_id' },
            { name: 'unit_price',
              type: 'integer',
              control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'amount', type: 'integer',
              control_type: 'integer',
              convert_input: 'integer_conversion',
              convert_output: 'integer_conversion' },
            { name: 'fulfillment_quantity',
              type: 'integer',
              control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'fulfillment_amount',
              type: 'integer',
              control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'tax_amount',
              type: 'integer',
              control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'amount_paid',
              type: 'integer',
              control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'amount_adjusted',
              type: 'integer',
              control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'refundable_credits_issued',
              type: 'integer',
              control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'refundable_credits',
              type: 'integer',
              control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'is_shippable',
              type: 'boolean',
              control_type: 'checkbox',
              convert_output: 'boolean_conversion' },
            { name: 'sku', label: 'SKU' },
            { name: 'status' },
            { name: 'object' },
            { name: 'entity_id' },
            { name: 'discount_amount',
              type: 'integer',
              control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'item_level_discount_amount',
              type: 'integer',
              control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'description' },
            { name: 'entity_type' }
          ] },
        { name: 'line_item_taxes', type: 'array', of: 'object',
          properties: [
            { name: 'line_item_id' },
            { name: 'tax_name' },
            { name: 'tax_rate',
              type: 'integer',
              control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'is_partial_tax_applied', type: 'boolean',
              control_type: 'checkbox',
              convert_output: 'boolean_conversion' },
            { name: 'is_non_compliance_tax', type: 'boolean',
              control_type: 'checkbox',
              convert_output: 'boolean_conversion' },
            { name: 'tax_juris_type' },
            { name: 'tax_juris_name' },
            { name: 'tax_juris_code' },
            { name: 'object' },
            { name: 'tax_amount',
              type: 'integer',
              control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'taxable_amount',
              type: 'integer',
              control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'tax_amount_in_local_currency',
              type: 'integer',
              control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'local_currency_code',
              type: 'integer',
              control_type: 'integer',
              convert_output: 'integer_conversion' }
          ] },
        { name: 'line_item_discounts', type: 'array', of: 'object',
          properties: [
            { name: 'line_item_id' },
            { name: 'discount_type' },
            { name: 'discount_amount', type: 'number', control_type: 'number' }
          ] },
        { name: 'total',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'amount_refundable',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'currency_code' },
        { name: 'base_currency_code' },
        { name: 'shipping_address',
          type: 'object',
          properties: call('business_address_schema', '') },
        { name: 'billing_address',
          type: 'object',
          properties: call('business_address_schema', '') },
        { name: 'linked_credit_notes', type: 'array', of: 'object',
          properties: [
            { name: 'amount',
              type: 'integer',
              control_type: 'number',
              convert_output: 'integer_conversion' },
            { name: 'type' },
            { name: 'id' },
            { name: 'status' },
            { name: 'amount_adjusted',
              type: 'integer',
              control_type: 'number',
              convert_output: 'integer_conversion' },
            { name: 'amount_refunded',
              type: 'integer',
              control_type: 'number',
              convert_output: 'integer_conversion' }
          ] },
        { name: 'resent_orders', type: 'array', of: 'object',
          properties: [
            { name: 'order_id' },
            { name: 'reason' },
            { name: 'amount', type: 'number', control_type: 'number' }
          ] }
      ]
    end,
    quote_schema: lambda do
      [
        { name: 'id' },
        { name: 'name' },
        { name: 'po_number', label: 'Purchase order number' },
        { name: 'customer_id' },
        { name: 'subscription_id' },
        { name: 'invoice_id' },
        { name: 'vat_number', label: 'VAT/ Tax registration number' },
        { name: 'sub_total', type: 'number', control_type: 'number' },
        { name: 'total', type: 'number', control_type: 'number' },
        { name: 'credits_applied', type: 'number', control_type: 'number' },
        { name: 'amount_paid', type: 'number', control_type: 'number' },
        { name: 'amount_due', type: 'number', control_type: 'number' },
        { name: 'version', type: 'integer', control_type: 'integer',
          convert_input: 'integer_conversion',
          convert_output: 'integer_conversion' },
        { name: 'vat_number_prefix', label: 'VAT number prefix' },
        { name: 'notes', type: 'array', of: 'string' },
        { name: 'contract_term_start', type: 'date_time', control_type: 'date_time',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'contract_term_end', type: 'date_time', control_type: 'date_time',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'contract_term_termination_fee', type: 'number',
          control_type: 'number' },
        { name: 'status' },
        { name: 'operation_type' },
        { name: 'price_type' },
        { name: 'valid_till', type: 'date_time', control_type: 'date_time',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'date', type: 'date_time', control_type: 'date_time',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'total_payable',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'charge_on_acceptance',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'updated_at', type: 'date_time', control_type: 'date_time',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'resource_version',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'object' },
        { name: 'currency_code' },
        { name: 'line_items', type: 'array', of: 'object',
          properties:
          [
            { name: 'reference_line_item_id', optional: false },
            { name: 'amount', type: 'number', control_type: 'number' },
            { name: 'customer_id' },
            { name: 'subscription_id' },
            { name: 'date_from', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
            { name: 'date_to', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
            { name: 'description' },
            { name: 'entity_description' },
            { name: 'entity_type' },
            { name: 'discount_amount', type: 'number', control_type: 'number' },
            { name: 'id' },
            { name: 'is_taxed', type: 'boolean', control_type: 'checkbox',
              convert_output: 'boolean_conversion' },
            { name: 'item_level_discount_amount', type: 'number',
              control_type: 'number' },
            { name: 'object' },
            { name: 'pricing_model' },
            { name: 'unit_amount_in_decimal' },
            { name: 'amount_in_decimal' },
            { name: 'quantity_in_decimal' },
            { name: 'tax_rate', type: 'number', control_type: 'number' },
            { name: 'quantity', type: 'integer', control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'tax_amount', type: 'integer', control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'tax_exempt_reason' },
            { name: 'entity_id' },
            { name: 'unit_amount', type: 'number', control_type: 'number' }
          ] },
        { name: 'discounts', type: 'array', of: 'object',
          properties: [
            { name: 'amount', type: 'number', control_type: 'number' },
            { name: 'description' },
            { name: 'line_item_id' },
            { name: 'entity_type' },
            { name: 'discount_type' },
            { name: 'entity_id' }
          ] },
        { name: 'line_item_discounts', type: 'array', of: 'object',
          properties: [
            { name: 'line_item_id' },
            { name: 'discount_type' },
            { name: 'coupon_id' },
            { name: 'discount_amount', type: 'number', control_type: 'number' }
          ] },
        { name: 'line_item_tiers', type: 'array', of: 'object',
          properties: [
            { name: 'line_item_id' },
            { name: 'starting_unit', type: 'integer', control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'ending_unit', type: 'integer', control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'quantity_used', type: 'integer', control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'unit_amount', type: 'number', control_type: 'number' },
            { name: 'starting_unit_in_decimal' },
            { name: 'ending_unit_in_decimal' },
            { name: 'quantity_used_in_decimal' },
            { name: 'unit_amount_in_decimal' }
          ] },
        { name: 'taxes', type: 'array', of: 'object',
          properties: [
            { name: 'name' },
            { name: 'amount', type: 'number', control_type: 'number' },
            { name: 'description' }
          ] },
        { name: 'line_item_taxes', type: 'array', of: 'object',
          properties: [
            { name: 'line_item_id' },
            { name: 'tax_name' },
            { name: 'tax_rate', type: 'number', control_type: 'number' },
            { name: 'is_partial_tax_applied', type: 'boolean', control_type: 'checkbox',
              convert_output: 'boolean_conversion' },
            { name: 'taxable_amount', type: 'number', control_type: 'number' },
            { name: 'tax_amount', type: 'number', control_type: 'number' },
            { name: 'tax_juris_type' },
            { name: 'tax_juris_name' },
            { name: 'tax_juris_code' },
            { name: 'tax_amount_in_local_currency', type: 'number', control_type: 'number' },
            { name: 'local_currency_code' }
          ] },
        { name: 'shipping_address', type: 'object',
          properties: [
            { name: 'first_name' },
            { name: 'last_name' },
            { name: 'email' },
            { name: 'company' },
            { name: 'phone' },
            { name: 'line1', label: 'Address line 1' },
            { name: 'line2', label: 'Address line 2' },
            { name: 'line3', label: 'Address line 3' },
            { name: 'city' },
            { name: 'state_code',
              hint: 'The ISO 3166-2 state/province code without the country prefix. ' \
                    'Currently supported for USA, Canada and India. For instance, for ' \
                    'Arizona (USA), set state_code as AZ (not US-AZ). For Tamil Nadu ' \
                    '(India), set as TN (not IN-TN). For British Columbia (Canada), ' \
                    'set as BC (not CA-BC).' },
            { name: 'state',
              hint: 'The state/province name. Is set by Chargebee automatically for ' \
                    'US, Canada and India If state_code is provided.' },
            { name: 'country', hint: 'ISO 3166 alpha-2 country code.' },
            { name: 'zip' },
            { name: 'validation_status', control_type: 'select',
              pick_list: 'validation_status_list',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'validation_status', control_type: 'text',
                type: 'string',
                label: 'Customer type',
                optional: true,
                toggle_hint: 'Use custom value',
                hint: 'Allowed vaalues are: not_validated, valid, partially_valid, invalid'
              },
              hint: 'The address verification status.' }
          ] },
        { name: 'billing_address', type: 'object', properties:
          call('business_address_schema', '') }
      ]
    end,
    quoted_subscription_schema: lambda do
      call('subscription_schema', '').
        only('id', 'start_date', 'trial_end', 'remaining_billing_cycles',
             'po_number', 'plan_quantity_in_decimal',
             'plan_unit_price_in_decimal', 'changes_scheduled_at',
             'contract_term_billing_cycle_on_renewal').
        concat([
                 { name: 'change_option' },
                 { name: 'coupons', type: 'array', of: 'object',
                   properties: [
                     { name: 'coupon_id' }
                   ] }
               ]).
        concat(call('quote_for_update_subscription_item_create_input', '').
        only('subscription_items', 'discounts', 'item_tiers')).
        concat([
                 { name: 'quoted_contract_term', type: 'object',
                   properties: [
                     { name: 'contract_start', type: 'date_time',
                       control_type: 'date_time',
                       convert_input: 'render_epoch_time',
                       convert_output: 'render_iso8601_timestamp' },
                     { name: 'contract_end', type: 'date_time',
                       control_type: 'date_time',
                       convert_input: 'render_epoch_time',
                       convert_output: 'render_iso8601_timestamp' },
                     { name: 'billing_cycles', type: 'integer',
                       control_type: 'integer',
                       convert_output: 'integer_conversion' },
                     { name: 'action_at_term_end' },
                     { name: 'total_contract_value', type: 'number',
                       control_type: 'number' },
                     { name: 'cancellation_cutoff_period', type: 'integer',
                       control_type: 'integer',
                       convert_output: 'integer_conversion' }
                   ] }
               ])
    end,
    coupon_get_input: lambda do
      [
        { name: 'id', label: 'Coupon ID', optional: false },
        {
          name: 'schema_builder',
          extends_schema: true,
          control_type: 'schema-designer',
          label: 'Data fields',
          sticky: true,
          empty_schema_title: 'Describe all fields for your meta fields.',
          hint: 'A set of key-value pairs stored as additional information for ' \
                'the coupon. Describe all your metadata fields.',
          optional: true,
          sample_data_type: 'json' # json_input / xml
        }
      ]
    end,
    coupon_get_output: lambda do |input|
      call('coupon_schema', input)
    end,
    coupon_search_input: lambda do
      [
        { name: 'sort_by', type: 'object', sticky: true,
          properties: [
            { name: 'value', label: 'Attribute',
              type: 'string', sticky: true,
              control_type: 'select', pick_list: [%w[Created\ At created_at]],
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Attribute',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'created_at'"
              } },
            { name: 'sort_order', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'sort_order_list',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'sort_order',
                label: 'Sort order',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'asc', 'desc'"
              } }
          ] },
        { name: 'created_at', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'timestamp_filter_types',
              extends_schema: true,
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                extends_schema: true,
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'after', 'before', 'on', 'between'"
              } },
            { ngIf: 'input.created_at.operator == "between"',
              name: 'from', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time',
              convert_output: 'render_iso8601_timestamp', sticky: true },
            { ngIf: 'input.created_at.operator == "between"',
              name: 'to', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time',
              convert_output: 'render_iso8601_timestamp', sticky: true },
            { ngIf: 'input.created_at.operator != "between"',
              name: 'value', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time',
              convert_output: 'render_iso8601_timestamp', sticky: true }
          ] },
        { name: 'discount_type', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'period_string_field_types',
              extends_schema: true,
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                extends_schema: true,
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'in', 'not_in'"
              } },
            { ngIf: 'input.discount_type.operator == "in" || input.discount_type.operator == "not_in"',
              name: 'value', type: 'string', sticky: true,
              control_type: 'multiselect', pick_list: 'discount_type',
              delimiter: ',',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'fixed_amount', 'percentage'. Multiple " \
                      "values can be seperated using comma(','). e.g. fixed_amount,percentage"
              } },
            { ngIf: '!(input.discount_type.operator == "in" || input.discount_type.operator == "not_in")',
              name: 'value', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'discount_type',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'fixed_amount', 'percentage'"
              } }
          ] },
        { name: 'duration_type', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'period_string_field_types',
              extends_schema: true,
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                extends_schema: true,
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'in', 'not_in'"
              } },
            { ngIf: 'input.duration_type.operator == "in" || input.duration_type.operator == "not_in"',
              name: 'value', type: 'string', sticky: true,
              control_type: 'multiselect', pick_list: 'duration_type',
              delimiter: ',',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'one_time', 'forever', 'limited_period'. " \
                      "Multiple values can be seperated using comma(','). e.g. one_time,forever"
              } },
            { ngIf: '!(input.duration_type.operator == "in" || input.duration_type.operator == "not_in")',
              name: 'value', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'duration_type',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'one_time', 'forever', 'limited_period'"
              } }
          ] },
        { name: 'status', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'period_string_field_types',
              extends_schema: true,
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                extends_schema: true,
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'in', 'not_in'"
              } },
            { ngIf: 'input.status.operator == "in" || input.status.operator == "not_in"',
              name: 'value', type: 'string', sticky: true,
              control_type: 'multiselect', pick_list: 'coupon_status',
              delimiter: ',',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'active', 'expired', 'archived', 'deleted'. " \
                      "Multiple values can be seperated using comma(','). e.g. active,expired"
              } },
            { ngIf: '!(input.status.operator == "in" || input.status.operator == "not_in")',
              name: 'value', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'coupon_status',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'active', 'expired', 'archived', 'deleted'"
              } }
          ] },
        { name: 'apply_on', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'period_string_field_types',
              extends_schema: true,
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                extends_schema: true,
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'in', 'not_in'"
              } },
            { ngIf: 'input.apply_on.operator == "in" || input.apply_on.operator == "not_in"',
              name: 'value', type: 'string', sticky: true,
              control_type: 'multiselect', pick_list: 'apply_on',
              delimiter: ',',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'invoice_amount', 'each_specified_item'. " \
                      "Multiple values can be seperated using comma(','). e.g. invoice_amount,each_specified_item"
              } },
            { ngIf: '!(input.apply_on.operator == "in" || input.apply_on.operator == "not_in")',
              name: 'value', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'apply_on',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'invoice_amount', 'each_specified_item'"
              } }
          ] }
      ].
        concat(call('plan_search_input').
          only('id', 'name', 'updated_at', 'currency_code', 'limit', 'offset', 'schema_builder'))
    end,
    coupon_search_output: lambda do |input|
      [
        { name: 'coupons', type: 'array', of: 'object',
          properties: call('coupon_schema', input) }
      ].
        concat([
                 { name: 'next_offset',
                   hint: 'This attribute is returned only if more resources are present. ' \
                     'To fetch the next set of resources use this value for the ' \
                     "input parameter 'offset'." }
               ])
    end,
    item_search_input: lambda do
      [
        { name: 'id', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'id_string_field_types',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'starts_with', 'in', 'not_in'"
              } },
            { name: 'value', sticky: true,
              hint: "Use comma(',') separated value for 'in' and 'not_in' operator. " \
                    'e.g. value1,value2' }
          ] },
        { name: 'item_family_id', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'id_string_field_types',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'starts_with', 'in', 'not_in'"
              } },
            { name: 'value', sticky: true,
              hint: "Use comma(',') separated value for 'in' and 'not_in' operator. " \
                    'e.g. value1,value2' }
          ] },
        { name: 'type', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'period_string_field_types',
              toggle_hint: 'Select from list',
              extends_schema: true,
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                extends_schema: true,
                hint: "Allowed values are 'is', 'is_not', 'in', 'not_in'"
              } },
            { ngIf: 'input.type.operator == "in" || input.type.operator == "not_in"',
              name: 'value', type: 'string', sticky: true,
              control_type: 'multiselect', pick_list: 'item_type',
              delimiter: ',',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'plan', 'addon', 'charge'. " \
                      "Multiple values can be seperated using comma(','). e.g. adjustment,refundable"
              } },
            { ngIf: '!(input.type.operator == "in" || input.type.operator == "not_in")',
              name: 'value', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'item_type',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'plan', 'addon', 'charge'"
              } }
          ] },
        { name: 'name', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'name_string_field_types',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'starts_with'"
              } },
            { name: 'value', sticky: true }
          ] },
        { name: 'item_applicability', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'period_string_field_types',
              toggle_hint: 'Select from list',
              extends_schema: true,
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                extends_schema: true,
                hint: "Allowed values are 'is', 'is_not', 'in', 'not_in'"
              } },
            { ngIf: 'input.item_applicability.operator == "in" || input.item_applicability.operator == "not_in"',
              name: 'value', type: 'string', sticky: true,
              control_type: 'multiselect', pick_list: 'addon_applicability',
              delimiter: ',',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'all', 'restricted'. " \
                      "Multiple values can be seperated using comma(','). e.g. all,restricted"
              } },
            { ngIf: '!(input.item_applicability.operator == "in" || input.item_applicability.operator == "not_in")',
              name: 'value', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'addon_applicability',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'all', 'restricted'"
              } }
          ] },
        { name: 'status', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'period_string_field_types',
              extends_schema: true,
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                extends_schema: true,
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'in', 'not_in'"
              } },
            { ngIf: 'input.status.operator == "in" || input.status.operator == "not_in"',
              name: 'value', type: 'string', sticky: true,
              control_type: 'multiselect', pick_list: 'item_status',
              delimiter: ',',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'active', 'deleted'. Multiple values " \
                      "can be seperated using comma(','). e.g. active,deleted"
              } },
            { ngIf: '!(input.status.operator == "in" || input.status.operator == "not_in")',
              name: 'value', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'item_status',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'active', 'deleted'"
              } }
          ] },
        { name: 'is_giftable', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'boolean_filter_types',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values is 'is'"
              } },
            { name: 'value',
              type: 'boolean', control_type: 'checkbox',
              convert_input: 'boolean_conversion',
              toggle_hint: 'Select from list',
              sticky: true,
              toggle_field: {
                name: 'value', label: 'Value',
                optional: true, sticky: true,
                type: 'string', control_type: 'text',
                convert_input: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true, false.'
              } }
          ] },
        { name: 'enabled_for_checkout', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'boolean_filter_types',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values is 'is'"
              } },
            { name: 'value',
              type: 'boolean', control_type: 'checkbox',
              convert_input: 'boolean_conversion',
              toggle_hint: 'Select from list',
              sticky: true,
              toggle_field: {
                name: 'value', label: 'Value',
                optional: true, sticky: true,
                type: 'string', control_type: 'text',
                convert_input: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true, false.'
              } }
          ] },
        { name: 'enabled_in_portal', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'boolean_filter_types',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values is 'is'"
              } },
            { name: 'value',
              type: 'boolean', control_type: 'checkbox',
              convert_input: 'boolean_conversion',
              toggle_hint: 'Select from list',
              sticky: true,
              toggle_field: {
                name: 'value', label: 'Value',
                optional: true, sticky: true,
                type: 'string', control_type: 'text',
                convert_input: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true, false.'
              } }
          ] },
        { name: 'metered', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'boolean_filter_types',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values is 'is'"
              } },
            { name: 'value',
              type: 'boolean', control_type: 'checkbox',
              convert_input: 'boolean_conversion',
              toggle_hint: 'Select from list',
              sticky: true,
              toggle_field: {
                name: 'value', label: 'Value',
                optional: true, sticky: true,
                type: 'string', control_type: 'text',
                convert_input: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true, false.'
              } }
          ] },
        { name: 'usage_calculation', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'period_string_field_types',
              toggle_hint: 'Select from list',
              extends_schema: true,
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                extends_schema: true,
                hint: "Allowed values are 'is', 'is_not', 'in', 'not_in'"
              } },
            { ngIf: 'input.usage_calculation.operator == "in" || input.usage_calculation.operator == "not_in"',
              name: 'value', type: 'string', sticky: true,
              control_type: 'multiselect', pick_list: 'usage_calculation',
              delimiter: ',',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'sum_of_usages', 'last_usage'. " \
                      "Multiple values can be seperated using comma(','). e.g. sum_of_usages,last_usage"
              } },
            { ngIf: '!(input.usage_calculation.operator == "in" || input.usage_calculation.operator == "not_in")',
              name: 'value', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'usage_calculation',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'sum_of_usages', 'last_usage'"
              } }
          ] },
        { name: 'sort_by', type: 'object', sticky: true,
          properties: [
            { name: 'value', label: 'Attribute',
              type: 'string', sticky: true,
              control_type: 'select', pick_list: 'attribute_list',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Attribute',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'created_at', 'updated_at'"
              } },
            { name: 'sort_order', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'sort_order_list',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'sort_order',
                label: 'Sort order',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'asc', 'desc'"
              } }
          ] }
      ].concat(call('plan_search_input').only('updated_at', 'limit', 'offset', 'schema_builder'))
    end,
    item_price_search_input: lambda do
      [
        { name: 'item_id', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'id_string_field_types',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'starts_with', 'in', 'not_in'"
              } },
            { name: 'value', sticky: true,
              hint: "Use comma(',') separated value for 'in' and 'not_in' operator. " \
                    'e.g. value1,value2' }
          ] },
        { name: 'item_type', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'period_string_field_types',
              toggle_hint: 'Select from list',
              extends_schema: true,
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                extends_schema: true,
                hint: "Allowed values are 'is', 'is_not', 'in', 'not_in'"
              } },
            { ngIf: 'input.item_type.operator == "in" || input.item_type.operator == "not_in"',
              name: 'value', type: 'string', sticky: true,
              control_type: 'multiselect', pick_list: 'item_type',
              delimiter: ',',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'plan', 'addon', 'charge'. " \
                      "Multiple values can be seperated using comma(','). e.g. adjustment,refundable"
              } },
            { ngIf: '!(input.item_type.operator == "in" || input.item_type.operator == "not_in")',
              name: 'value', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'item_type',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'plan', 'addon', 'charge'"
              } }
          ] },
        { name: 'status', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'period_string_field_types',
              extends_schema: true,
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                extends_schema: true,
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'in', 'not_in'"
              } },
            { ngIf: 'input.status.operator == "in" || input.status.operator == "not_in"',
              name: 'value', type: 'string', sticky: true,
              control_type: 'multiselect', pick_list: 'item_price_status',
              delimiter: ',',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'active', 'deleted', 'archived'. Multiple values " \
                      "can be seperated using comma(','). e.g. active,deleted"
              } },
            { ngIf: '!(input.status.operator == "in" || input.status.operator == "not_in")',
              name: 'value', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'item_price_status',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'active', 'deleted', 'archived'"
              } }
          ] }
      ].concat(call('plan_search_input').only('name', 'period',
                                              'period_unit', 'trial_period', 'trial_period_unit',
                                              'pricing_model', 'currency_code')).
        concat(call('item_search_input').only('id', 'limit', 'offset', 'sort_by',
                                              'item_family_id', 'updated_at', 'schema_builder'))
    end,
    item_search_output: lambda do |input|
      [
        { name: 'items', type: 'array', of: 'object',
          properties: call('item_schema', input) }
      ].
        concat([
                 { name: 'next_offset',
                   hint: 'This attribute is returned only if more resources are present. ' \
                     'To fetch the next set of resources use this value for the ' \
                     "input parameter 'offset'." }
               ])
    end,
    item_price_search_output: lambda do |input|
      [
        { name: 'item_prices', type: 'array', of: 'object',
          properties: call('item_price_schema', input) }
      ].
        concat([
                 { name: 'next_offset',
                   hint: 'This attribute is returned only if more resources are present. ' \
                     'To fetch the next set of resources use this value for the ' \
                     "input parameter 'offset'." }
               ])
    end,
    differential_price_schema: lambda do |_input|
      [
        { name: 'id' },
        { name: 'currency_code' },
        { name: 'item_price_id' },
        { name: 'object' },
        { name: 'parent_item_id' },
        { name: 'price',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'price_in_decimal' },
        { name: 'resource_version',
          type: 'integer',
          control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'created_at',
          type: 'date_time',
          control_type: 'date_time',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'modified_at',
          type: 'date_time',
          control_type: 'date_time',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'status' },
        { name: 'updated_at',
          type: 'date_time',
          control_type: 'date_time',
          convert_output: 'render_iso8601_timestamp' },
        { name: 'tiers',
          type: 'array',
          of: 'object',
          properties: [
            { name: 'starting_unit',
              type: 'integer',
              control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'ending_unit',
              type: 'integer',
              control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'price',
              type: 'integer',
              control_type: 'number',
              convert_output: 'integer_conversion' }
          ] },
        { name: 'parent_periods',
          type: 'array',
          of: 'object',
          properties: [
            { name: 'parent_unit' },
            { name: 'period' }
          ] }
      ]
    end,
    credit_note_schema: lambda do
      [
        { name: 'id' },
        { name: 'customer_id' },
        { name: 'amount_allocated', type: 'integer', control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'amount_available', type: 'integer', control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'amount_refunded', type: 'integer', control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'base_currency_code' },
        { name: 'create_reason_code',
          hint: 'Reason code for creating the credit note. Must be one from a list of ' \
                'reason codes set in the Chargebee app in Settings > Configure Chargebee > ' \
                'Reason Codes > Credit Notes > Create Credit Note. Must be passed if ' \
                'set as mandatory in the app. The codes are case-sensitive.' },
        { name: 'currency_code' },
        { name: 'refunded_at', type: 'number', control_type: 'number' },
        { name: 'voided_at', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
        { name: 'subscription_id' },
        { name: 'date', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp',
          hint: 'The date the Credit Note is issued.' },
        { name: 'deleted', type: 'boolean', control_type: 'checkbox',
          convert_output: 'boolean_conversion' },
        { name: 'customer_notes',
          hint: 'A note to be added for this operation, to the credit note. This note ' \
                'is displayed on customer-facing documents such as the Credit Note PDF.' },
        { name: 'comment',
          hint: 'An internal comment to be added for this operation, to the credit ' \
                'note. This comment is displayed on the Chargebee UI. It is not ' \
                'displayed on any customer-facing Hosted Page or any document ' \
                'such as the Credit Note PDF.' },
        { name: 'exchange_rate', type: 'integer', control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'price_type' },
        { name: 'object' },
        { name: 'reason_code', type: 'string', sticky: true,
          control_type: 'select', pick_list: 'credit_note_reason_code',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'reason_code',
            label: 'Reason code',
            optional: true,
            sticky: true,
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: "Allowed values are 'product_unsatisfactory', 'service_unsatisfactory', " \
                  "'order_change', 'order_cancellation', 'waiver', 'other'"
          } },
        { name: 'reference_invoice_id', optional: false,
          hint: 'The identifier of the invoice against which this Credit Note is issued.' },
        { name: 'resource_version', type: 'number', control_type: 'number' },
        { name: 'status' },
        { name: 'vat_number', label: 'VAT number' },
        { name: 'sub_total', type: 'number', control_type: 'number' },
        { name: 'sub_total_in_local_currency', type: 'number', control_type: 'number' },
        { name: 'total_in_local_currency', type: 'number', control_type: 'number' },
        { name: 'local_currency_code' },
        { name: 'round_off_amount', type: 'number', control_type: 'number' },
        { name: 'fractional_correction', type: 'number', control_type: 'number' },
        { name: 'total', type: 'number', control_type: 'number',
          hint: 'Credit Note amount in cents. You can either pass the total parameter ' \
                'or the line_items parameter. Passing both will result in an error.' },
        { name: 'type', type: 'string', optional: false,
          control_type: 'select', pick_list: 'credit_note_type_list',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'type',
            label: 'Type',
            optional: false,
            sticky: true,
            type: 'string',
            control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: "Allowed values are 'adjustment', 'refundable'"
          } },
        { name: 'updated_at', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
        { name: 'generated_at', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
        { name: 'vat_number_prefix', label: 'VAT number prefix' },
        { name: 'einvoice', label: 'E-invoice', type: 'object',
          properties: [
            { name: 'id' },
            { name: 'status' },
            { name: 'message' }
          ] },
        { name: 'linked_tax_withheld_refunds', type: 'array', of: 'object',
          properties: [
            { name: 'id' },
            { name: 'amount', type: 'intger', control_type: 'integer',
              convert_input: 'integer_conversion',
              convert_output: 'integer_conversion' },
            { name: 'description' },
            { name: 'date', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time',
              convert_output: 'render_iso8601_timestamp' },
            { name: 'reference_number' }
          ] },
        { name: 'line_items', type: 'array', of: 'object',
          properties: call('line_items_schema') },
        { name: 'discounts', type: 'array', of: 'object',
          properties: [
            { name: 'amount', type: 'number', control_type: 'number' },
            { name: 'description' },
            { name: 'line_item_id' },
            { name: 'entity_type' },
            { name: 'entity_id' }
          ] },
        { name: 'line_item_discounts', type: 'array', of: 'object',
          properties: [
            { name: 'line_item_id' },
            { name: 'discount_type' },
            { name: 'coupon_id' },
            { name: 'discount_amount', type: 'number', control_type: 'number' }
          ] },
        { name: 'line_item_tiers', type: 'array', of: 'object',
          properties: [
            { name: 'line_item_id' },
            { name: 'starting_unit', type: 'integer', control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'ending_unit', type: 'integer', control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'quantity_used', type: 'integer', control_type: 'integer',
              convert_output: 'integer_conversion' },
            { name: 'unit_amount', type: 'number', control_type: 'number' },
            { name: 'starting_unit_in_decimal' },
            { name: 'ending_unit_in_decimal' },
            { name: 'quantity_used_in_decimal' },
            { name: 'unit_amount_in_decimal' }
          ] },
        { name: 'taxes', type: 'array', of: 'object',
          properties: [
            { name: 'name' },
            { name: 'amount', type: 'number', control_type: 'number' },
            { name: 'description' }
          ] },
        { name: 'line_item_taxes', type: 'array', of: 'object',
          properties: [
            { name: 'line_item_id' },
            { name: 'tax_name' },
            { name: 'tax_rate', type: 'number', control_type: 'number' },
            { name: 'is_partial_tax_applied', type: 'boolean', control_type: 'checkbox',
              convert_output: 'boolean_conversion' },
            { name: 'is_non_compliance_tax', type: 'boolean', control_type: 'checkbox',
              convert_output: 'boolean_conversion' },
            { name: 'taxable_amount', type: 'number', control_type: 'number' },
            { name: 'tax_amount', type: 'number', control_type: 'number' },
            { name: 'tax_juris_type' },
            { name: 'tax_juris_name' },
            { name: 'tax_juris_code' },
            { name: 'tax_amount_in_local_currency', type: 'number', control_type: 'number' },
            { name: 'local_currency_code' }
          ] },
        { name: 'linked_refunds', type: 'array', of: 'object',
          properties: [
            { name: 'txn_id', label: 'Transaction ID' },
            { name: 'applied_amount', type: 'number', control_type: 'number' },
            { name: 'applied_at', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
            { name: 'txn_status', label: 'Transaction status' },
            { name: 'txn_date', label: 'Transaction date',
              type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
            { name: 'txn_amount', label: 'Transaction amount',
              type: 'number', control_type: 'number' },
            { name: 'refund_reason_code' }
          ] },
        { name: 'allocations', type: 'array', of: 'object',
          properties: [
            { name: 'invoice_id' },
            { name: 'allocated_amount', type: 'number', control_type: 'number' },
            { name: 'allocated_at', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
            { name: 'invoice_date', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
            { name: 'invoice_status' }
          ] }
      ]
    end,
    line_items_schema: lambda do
      [
        { name: 'id' },
        { name: 'reference_line_item_id', optional: false },
        { name: 'amount', type: 'number', control_type: 'number' },
        { name: 'customer_id' },
        { name: 'subscription_id' },
        { name: 'date_from', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
        { name: 'date_to', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
        { name: 'description' },
        { name: 'entity_description' },
        { name: 'entity_type' },
        { name: 'discount_amount', type: 'number', control_type: 'number' },
        { name: 'is_taxed', type: 'boolean', control_type: 'checkbox',
          convert_output: 'boolean_conversion' },
        { name: 'item_level_discount_amount', type: 'number',
          control_type: 'number' },
        { name: 'object' },
        { name: 'pricing_model' },
        { name: 'unit_amount_in_decimal' },
        { name: 'amount_in_decimal' },
        { name: 'quantity_in_decimal' },
        { name: 'tax_rate', type: 'number', control_type: 'number' },
        { name: 'quantity', type: 'integer', control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'tax_amount', type: 'integer', control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'tax_exempt_reason' },
        { name: 'entity_id' },
        { name: 'unit_amount', type: 'number', control_type: 'number' }
      ]
    end,
    transaction_schema: lambda do
      [
        { name: 'id' },
        { name: 'customer_id' },
        { name: 'subscription_id' },
        { name: 'amount', type: 'number', control_type: 'number' },
        { name: 'amount_capturable', type: 'number', control_type: 'number' },
        { name: 'authorization_reason' },
        { name: 'error_code' },
        { name: 'error_text' },
        { name: 'reversal_transaction_id' },
        { name: 'base_currency_code' },
        { name: 'currency_code' },
        { name: 'voided_at', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
        { name: 'date', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
        { name: 'deleted', type: 'boolean', control_type: 'checkbox',
          convert_output: 'boolean_conversion' },
        { name: 'exchange_rate', type: 'integer', control_type: 'integer',
          convert_output: 'integer_conversion' },
        { name: 'fraud_reason' },
        { name: 'amount_unused', type: 'number', control_type: 'number' },
        { name: 'gateway' },
        { name: 'gateway_account_id' },
        { name: 'id_at_gateway' },
        { name: 'masked_card_number' },
        { name: 'reference_transaction_id' },
        { name: 'object' },
        { name: 'refunded_txn_id', label: 'Refunded transaction ID' },
        { name: 'reference_authorization_id' },
        { name: 'payment_method' },
        { name: 'reference_number' },
        { name: 'payment_source_id' },
        { name: 'resource_version', type: 'number', control_type: 'number' },
        { name: 'status' },
        { name: 'fraud_flag' },
        { name: 'initiator_type' },
        { name: 'type' },
        { name: 'three_d_secure', label: '3D secure', type: 'boolean',
          control_type: 'checkbox', convert_output: 'boolean_conversion' },
        { name: 'settled_at', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
        { name: 'updated_at', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
        { name: 'iin' },
        { name: 'last4' },
        { name: 'merchant_reference_id' },
        { name: 'linked_invoices', type: 'array', of: 'object',
          properties: [
            { name: 'invoice_id' },
            { name: 'applied_amount', type: 'number', control_type: 'number' },
            { name: 'applied_at', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
            { name: 'invoice_date', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
            { name: 'invoice_total', type: 'number', control_type: 'number' },
            { name: 'invoice_status' }
          ] },
        { name: 'linked_credit_notes', type: 'array', of: 'object',
          properties: [
            { name: 'cn_id', label: 'Credit notes ID' },
            { name: 'applied_amount', type: 'number', control_type: 'number' },
            { name: 'applied_at', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
            { name: 'cn_reason_code', label: 'Credit note reason code' },
            { name: 'cn_create_reason_code', label: 'Credit note create reason code' },
            { name: 'cn_date', label: 'Credit note date' },
            { name: 'cn_total', label: 'Credit note total' },
            { name: 'cn_status', label: 'Credit status' },
            { name: 'cn_reference_invoice_id', label: 'Credit reference invoice ID' }
          ] },
        { name: 'linked_refunds', type: 'array', of: 'object',
          properties: [
            { name: 'txn_id', label: 'Transaction ID' },
            { name: 'txn_status', label: 'Transaction status' },
            { name: 'txn_date', label: 'Transaction date',
              type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
            { name: 'txn_amount', label: 'Transaction amount' }
          ] },
        { name: 'linked_payments', type: 'array', of: 'object',
          properties: [
            { name: 'id' },
            { name: 'status' },
            { name: 'amount', type: 'number', control_type: 'number' },
            { name: 'date', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' }
          ] }
      ]
    end,
    business_address_schema: lambda do |_input|
      [
        { name: 'first_name',
          hint: 'The first name of the billing contact.' },
        { name: 'last_name',
          hint: 'The last name of the billing contact.' },
        { name: 'email', control_type: 'email',
          hint: 'The email address.' },
        { name: 'company', label: 'Company name',
          hint: 'Name of the company.' },
        { name: 'phone', label: 'Phone Number' },
        { name: 'line1', label: 'Address line 1' },
        { name: 'line2', label: 'Address line 2' },
        { name: 'line3', label: 'Address line 3' },
        { name: 'city', hint: 'Name of the city' },
        { name: 'state_code',
          hint: 'The ISO 3166-2 state/province code without the country' \
          ' prefix. Currently supported for USA, Canada and India' },
        { name: 'state', hint: 'Name of the state.' },
        { name: 'country', label: 'Country code',
          hint: '2-letter, ISO 3166 alpha-2 country code.' },
        { name: 'zip', hint: 'Zip or Postal code.' },
        { name: 'validation_status', control_type: 'select',
          pick_list: 'validation_status_list',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'validation_status', control_type: 'text',
            type: 'string', optional: true,
            label: 'Customer type',
            toggle_hint: 'Use custom value',
            hint: 'Allowed vaalues are: not_validated, valid, partially_valid, invalid'
          },
          hint: 'The address verification status.' }
      ]
    end,
    referral_url_schema: lambda do |_input|
      [
        { name: 'external_customer_id' },
        { name: 'referral_sharing_url' },
        { name: 'created_at', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
        { name: 'updated_at', type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
        { name: 'referral_campaign_id' },
        { name: 'referral_account_id' },
        { name: 'referral_external_campaign_id' },
        { name: 'referral_system', control_type: 'select',
          pick_list: 'referral_system_list',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'referral_system', control_type: 'text',
            type: 'string', optional: true,
            label: 'Referral system',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: referral_candy, referral_saasquatch, ' \
            'friendbuy'
          },
          hint: 'Url for the referral system account.' }
      ]
    end,
    contact_schema: lambda do |_input|
      [
        { name: 'id' },
        { name: 'first_name' },
        { name: 'last_name' },
        { name: 'email' },
        { name: 'phone' },
        { name: 'label' },
        {
          name: 'enabled', type: 'boolean',
          control_type: 'checkbox',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'enabled',
            type: 'boolean',
            control_type: 'text',
            label: 'Enabled', optional: true,
            toggle_hint: 'Use custom value',
            hint: 'Contact enabled / disabled. ' \
              'Allowed values are true, false'
          },
          hint: 'Contact enabled / disabled'
        },
        {
          name: 'send_account_email', type: 'boolean',
          control_type: 'checkbox',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'send_account_email',
            type: 'boolean',
            control_type: 'text', optional: true,
            label: 'Send account email',
            toggle_hint: 'Use custom value',
            hint: 'Whether Account Emails option is enabled for the contact. ' \
              'Allowed values are true, false'
          },
          hint: 'Whether Account Emails option is enabled for the contact.'
        },
        {
          name: 'send_billing_email', type: 'boolean',
          control_type: 'checkbox',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'send_billing_email',
            type: 'boolean', optional: true,
            control_type: 'text',
            label: 'Send billing email',
            toggle_hint: 'Use custom value',
            hint: 'Whether Billing Emails option is enabled for the contact. ' \
              'Allowed values are true, false'
          },
          hint: 'Whether Billing Emails option is enabled for the contact.'
        }
      ]
    end,
    payment_method_schema: lambda do |_|
      [
        { name: 'type', control_type: 'select',
          pick_list: 'payment_method_type_list',
          hint: 'The type of payment method.',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'type', control_type: 'text', label: 'Type',
            type: 'string', optional: true,
            label: 'Payment method type',
            toggle_hint: 'Use custom value',
            hint: 'Type of payment source. e.g. <b>alipay<b> for Alipay payments '
          } },
        { name: 'gateway', control_type: 'select',
          pick_list: 'payment_gateway_list',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'gateway', control_type: 'text', label: 'Gateway',
            type: 'string', optional: true,
            label: 'Payment method gateway',
            toggle_hint: 'Use custom value',
            hint: 'Name of the gateway the payment method is associated with.' \
            ' e.g. <b>chargebee<b> for Chargebee test gateway'
          },
          hint: 'Name of the gateway the payment method is associated with.' },
        { name: 'gateway_account_id' },
        { name: 'status', control_type: 'select',
          pick_list: 'card_status_list',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'status', control_type: 'text', label: 'Status',
            type: 'string', optional: true,
            label: 'Payment method status',
            toggle_hint: 'Use custom value',
            hint: 'Current status of the payment source..' \
            ' e.g. <b>valid<b> for payment source that is valid and active.'
          },
          hint: 'Current status of the payment source.' },
        { name: 'reference_id',
          hint: 'For Amazon and PayPal this will be the billing agreement id.' \
          ' For GoCardless direct debit this will be mandate id. In the case of' \
          ' card this will be the identifier provided by the gateway/card vault' \
          ' for the specific payment method resource.' },
        { name: 'tmp_token', label: 'Temporary token',
          hint: 'Single-use tokens created by payment gateways. In Stripe, a ' \
                'single-use token is created for Apple Pay Wallet, card ' \
                'details or direct debit. In Braintree, a nonce is created ' \
                'for Apple Pay Wallet, PayPal, or card details. In ' \
                'Authorize.Net, a nonce is created for card details. ' \
                'In Adyen, an encrypted data is created from the ' \
                'card details. <b>Required if referrence ID is not provided</b>' },
        { name: 'issuing_country',
          hint: 'Supports only ISO 3166 alpha-2 country code.' },
        { name: 'additional_information' }
      ]
    end,
    balance_schema: lambda do |_input|
      [
        { name: 'promotional_credits', type: 'integer',
          hint: 'Promotional credits balance of this customer in cents' },
        { name: 'excess_payments', type: 'integer',
          hint: 'Total unused payments associated with the customer in cents' },
        { name: 'refundable_credits', type: 'integer',
          hint: 'Refundable credits balance of this customer in cents' },
        { name: 'unbilled_charges', type: 'integer',
          hint: 'Total unbilled charges for this customer in cents' },
        { name: 'currency_code',
          hint: 'The currency code (ISO 4217 format) for balance.' }
      ]
    end,
    relationship_schema: lambda do |_input|
      [
        { name: 'parent_id' },
        { name: 'payment_owner_id' },
        { name: 'invoice_owner_id' }
      ]
    end,
    parent_account_access_schema: lambda do |_|
      [
        { name: 'portal_edit_child_subscriptions', control_type: 'select',
          pick_list: 'portal_edit_child_subscriptions_list',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'portal_edit_child_subscriptions', control_type: 'text',
            type: 'string', optional: true,
            label: 'Portal edit child subscriptions',
            toggle_hint: 'Use custom value',
            hint: 'Sets parent\'s level of access to child subscriptions on ' \
            'the Self-Serve Portal. Allowed values are: yes, view_only, no'
          },
          hint: 'Sets parent\'s level of access to child subscriptions ' \
          'on the Self-Serve Portal.' },
        { name: 'portal_download_child_invoices', control_type: 'select',
          pick_list: 'portal_edit_child_subscriptions_list',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'portal_download_child_invoices', control_type: 'text',
            type: 'string', optional: true,
            label: 'Portal download child invoices',
            toggle_hint: 'Use custom value',
            hint: 'Sets parent\'s level of access to child invoices on ' \
            'the Self-Serve Portal. Allowed values are: yes, view_only, no'
          },
          hint: 'Sets parent\'s level of access to child invoices on' \
          ' the Self-Serve Portal.' },
        {
          name: 'send_subscription_emails', type: 'boolean',
          control_type: 'checkbox',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'send_subscription_emails',
            type: 'boolean', optional: true,
            control_type: 'text',
            label: 'Send subscription emails',
            toggle_hint: 'Use custom value',
            hint: 'If true, the parent account will receive subscription-related' \
            ' emails sent to the child account. Allowed values are true, false'
          },
          hint: 'If true, the parent account will receive subscription-related' \
          ' emails sent to the child account.'
        },
        {
          name: 'send_invoice_emails', type: 'boolean',
          control_type: 'checkbox',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'send_invoice_emails',
            type: 'boolean',
            control_type: 'text', optional: true,
            label: 'Send invoice emails',
            toggle_hint: 'Use custom value',
            hint: 'If true, the parent account will receive invoice-related emails' \
            ' sent to the child account.. Allowed values are true, false'
          },
          hint: 'If true, the parent account will receive invoice-related emails' \
          ' sent to the child account.'
        },
        {
          name: 'send_payment_emails', type: 'boolean',
          control_type: 'checkbox',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'send_payment_emails',
            type: 'boolean', optional: false,
            control_type: 'text',
            label: 'Send payment emails',
            toggle_hint: 'Use custom value',
            hint: 'If true, the parent account will receive payment-related emails' \
            ' sent to the child account. Allowed values are true, false'
          },
          hint: 'If true, the parent account will receive payment-related emails' \
          ' sent to the child account'
        }
      ]
    end,
    child_account_access_schema: lambda do |_|
      [
        { name: 'portal_edit_subscriptions', control_type: 'select',
          pick_list: 'portal_edit_subscriptions_list',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'portal_edit_subscriptions', control_type: 'text',
            type: 'string', optional: true,
            label: 'Portal edit subscriptions',
            toggle_hint: 'Use custom value',
            hint: 'Sets the child\'s level of access to its own subscriptions on ' \
            'the Self-Serve Portal. Allowed values are: yes, view_only'
          },
          hint: 'Sets the child\'s level of access to its own subscriptions' \
          ' on the Self-Serve Portal' },
        { name: 'portal_download_invoices', control_type: 'select',
          pick_list: 'portal_download_invoices_list',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'portal_download_invoices', control_type: 'text',
            type: 'string', optional: true,
            label: 'Portal download invoices',
            toggle_hint: 'Use custom value',
            hint: 'Sets the child’s level of access to its own invoices on the ' \
            'Self-Serve Portal. Allowed values are: yes, view_only, no'
          },
          hint: 'Sets the child’s level of access to its own invoices on the' \
          ' Self-Serve Portal' },
        {
          name: 'send_subscription_emails', type: 'boolean',
          control_type: 'checkbox',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'send_subscription_emails',
            type: 'boolean', optional: true,
            control_type: 'text',
            label: 'Send subscription emails',
            toggle_hint: 'Use custom value',
            hint: 'If true, the parent account will receive subscription-related' \
            ' emails sent to the child account. Allowed values are true, false'
          },
          hint: 'If true, the parent account will receive subscription-related' \
          ' emails sent to the child account.'
        },
        {
          name: 'send_invoice_emails', type: 'boolean',
          control_type: 'checkbox',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'send_invoice_emails',
            type: 'boolean', optional: true,
            control_type: 'text',
            label: 'Send invoice emails',
            toggle_hint: 'Use custom value',
            hint: 'If true, the parent account will receive invoice-related emails' \
            ' sent to the child account.. Allowed values are true, false'
          },
          hint: 'If true, the parent account will receive invoice-related emails' \
          ' sent to the child account.'
        },
        {
          name: 'send_payment_emails', type: 'boolean',
          control_type: 'checkbox',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'send_payment_emails',
            type: 'boolean', optional: true,
            control_type: 'text',
            label: 'Send payment emails',
            toggle_hint: 'Use custom value',
            hint: 'If true, the parent account will receive payment-related emails' \
            ' sent to the child account. Allowed values are true, false'
          },
          hint: 'If true, the parent account will receive payment-related emails' \
          ' sent to the child account'
        }
      ]
    end,
    plan_search_input: lambda do
      [
        { name: 'id', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'id_string_field_types',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'starts_with', 'in', 'not_in'"
              } },
            { name: 'value', sticky: true,
              hint: "Use comma(',') separated value for 'in' and 'not_in' operator. " \
                    'e.g. value1,value2' }
          ] },
        { name: 'name', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'id_string_field_types',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'starts_with', 'in', 'not_in'"
              } },
            { name: 'value', sticky: true,
              hint: "Use comma(',') separated value for 'in' and 'not_in' operator. " \
                    'e.g. value1,value2' }
          ] },
        { name: 'price', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'number_filter_types',
              toggle_hint: 'Select from list',
              extends_schema: true,
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                extends_schema: true,
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'lt', 'lte', 'gt', 'gte', 'between'"
              } },
            { ngIf: 'input.price.operator == "between"',
              name: 'from', sticky: true,
              type: 'number', control_type: 'number' },
            { ngIf: 'input.price.operator == "between"',
              name: 'to', sticky: true,
              type: 'number', control_type: 'number' },
            { ngIf: 'input.price.operator != "between"',
              name: 'value', sticky: true,
              type: 'number', control_type: 'number' }
          ] },
        { name: 'period', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'number_filter_types',
              extends_schema: true,
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                extends_schema: true,
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'lt', 'lte', 'gt', 'gte', 'between'"
              } },
            { ngIf: 'input.period.operator == "between"',
              name: 'from', sticky: true,
              type: 'number', control_type: 'number' },
            { ngIf: 'input.period.operator == "between"',
              name: 'to', sticky: true,
              type: 'number', control_type: 'number' },
            { ngIf: 'input.period.operator != "between"',
              name: 'value', sticky: true,
              type: 'number', control_type: 'number' }
          ] },
        { name: 'period_unit', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'period_string_field_types',
              toggle_hint: 'Select from list',
              extends_schema: true,
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                extends_schema: true,
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'in', 'not_in'"
              } },
            { ngIf: 'input.period_unit.operator == "in" || input.period_unit.operator == "not_in"',
              name: 'value', type: 'string', sticky: true,
              control_type: 'multiselect', pick_list: 'period_unit',
              delimiter: ',',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'day', 'week', 'month', 'year'. " \
                      "Multiple values can be seperated using comma(','). e.g. day,week"
              } },
            { ngIf: '!(input.period_unit.operator == "in" || input.period_unit.operator == "not_in")',
              name: 'value', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'period_unit',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'day', 'week', 'month', 'year'"
              } }
          ] },
        { name: 'trial_period', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'trial_number_filter_types',
              extends_schema: true,
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                extends_schema: true,
                toggle_hint: 'Use custom value',
                hint: "Allowed values are  'is', 'is_not', 'lt', 'lte', 'gt', " \
                  "'gte', 'between', 'is_present'"
              } },
            { ngIf: 'input.trial_period.operator == "between"',
              name: 'from', type: 'integer', control_type: 'integer',
              convert_input: 'integer_conversion', sticky: true },
            { ngIf: 'input.trial_period.operator == "between"',
              name: 'to', type: 'integer', control_type: 'integer',
              convert_input: 'integer_conversion', sticky: true },
            { ngIf: 'input.trial_period.operator != "between"',
              name: 'value', type: 'integer', control_type: 'integer',
              convert_input: 'integer_conversion', sticky: true,
              hint: "If operator is 'is_present', allowed values are true/false" }
          ] },
        { name: 'trial_period_unit', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'period_string_field_types',
              toggle_hint: 'Select from list',
              extends_schema: true,
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                extends_schema: true,
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'in', 'not_in'"
              } },
            { ngIf: 'input.trial_period_unit.operator == "in" || input.trial_period_unit.operator == "not_in"',
              name: 'value', type: 'string', sticky: true,
              control_type: 'multiselect', pick_list: 'trial_period_unit',
              delimiter: ',',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'day', 'month'. Multiple values can " \
                      "be seperated using comma(','). e.g. day,month"
              } },
            { ngIf: '!(input.trial_period_unit.operator == "in" || input.trial_period_unit.operator == "not_in")',
              name: 'value', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'trial_period_unit',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'day', 'month'"
              } }
          ] },
        { name: 'addon_applicability', label: 'Add-on applicability', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'period_string_field_types',
              toggle_hint: 'Select from list',
              extends_schema: true,
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                extends_schema: true,
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'in', 'not_in'"
              } },
            { ngIf: 'input.addon_applicability.operator == "in" || input.addon_applicability.operator == "not_in"',
              name: 'value', type: 'string', sticky: true,
              control_type: 'multiselect', pick_list: 'addon_applicability',
              delimiter: ',',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'all', 'restricted'. Multiple values " \
                      "can be seperated using comma(','). e.g. all,restricted"
              } },
            { ngIf: '!(input.addon_applicability.operator == "in" || input.addon_applicability.operator == "not_in")',
              name: 'value', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'addon_applicability',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'all', 'restricted'"
              } }
          ] },
        { name: 'giftable', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'boolean_filter_types',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values is 'is'"
              } },
            { name: 'value',
              type: 'boolean', control_type: 'checkbox',
              convert_input: 'boolean_conversion',
              toggle_hint: 'Select from list',
              sticky: true,
              toggle_field: {
                name: 'value', label: 'Value',
                optional: true, sticky: true,
                type: 'string', control_type: 'text',
                convert_input: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true, false.'
              } }
          ] },
        { name: 'pricing_model', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'period_string_field_types',
              toggle_hint: 'Select from list',
              extends_schema: true,
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                extends_schema: true,
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'in', 'not_in'"
              } },
            { ngIf: 'input.pricing_model.operator == "in" || input.pricing_model.operator == "not_in"',
              name: 'value', type: 'string', sticky: true,
              control_type: 'multiselect', pick_list: 'pricing_model',
              delimiter: ',',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'flat_fee', 'per_unit', " \
                      "'tiered', 'volume', 'stairstep'. Multiple values can be " \
                      "seperated using comma(','). e.g. flat_free,per_unit"
              } },
            { ngIf: '!(input.pricing_model.operator == "in" || input.pricing_model.operator == "not_in")',
              name: 'value', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'pricing_model',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'flat_fee', 'per_unit', " \
                      "'tiered', 'volume', 'stairstep'."
              } }
          ] },
        { name: 'status', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'period_string_field_types',
              extends_schema: true,
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                extends_schema: true,
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'in', 'not_in'"
              } },
            { ngIf: 'input.status.operator == "in" || input.status.operator == "not_in"',
              name: 'value', type: 'string', sticky: true,
              control_type: 'multiselect', pick_list: 'status',
              delimiter: ',',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'active', 'archived'. Multiple values " \
                      "can be seperated using comma(','). e.g. active,archived"
              } },
            { ngIf: '!(input.status.operator == "in" || input.status.operator == "not_in")',
              name: 'value', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'status',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'active', 'archived'"
              } }
          ] },
        { name: 'updated_at', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'timestamp_filter_types',
              extends_schema: true,
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                extends_schema: true,
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'after', 'before', 'on', 'between'"
              } },
            { ngIf: 'input.updated_at.operator == "between"',
              name: 'from', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time',
              convert_output: 'render_iso8601_timestamp', sticky: true },
            { ngIf: 'input.updated_at.operator == "between"',
              name: 'to', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time',
              convert_output: 'render_iso8601_timestamp', sticky: true },
            { ngIf: 'input.updated_at.operator != "between"',
              name: 'value', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time',
              convert_output: 'render_iso8601_timestamp', sticky: true }
          ] },
        { name: 'currency_code', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'id_string_field_types',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', starts_with, 'in', 'not_in'"
              } },
            { name: 'value', sticky: true,
              hint: "Use comma(',') separated value for 'in' and 'not_in' operator. " \
                    'e.g. value1,value2' }
          ] },
        { name: 'limit',
          type: 'integer', control_type: 'integer',
          convert_input: 'integer_conversion',
          hint: 'The number of resources to be returned. ' \
            'Default value is 10 and Maximum is 100' },
        { name: 'offset',
          hint: 'Determines your position in the list for pagination. To ensure ' \
            'that the next page is retrieved correctly, always set offset ' \
            'to the value of next_offset obtained in the previous ' \
            'iteration of the API call.' },
        { name: 'schema_builder',
          extends_schema: true,
          control_type: 'schema-designer',
          label: 'Data fields',
          sticky: true,
          empty_schema_title: 'Describe all fields for your metadata fields.',
          optional: true,
          hint: 'A set of key-value pairs stored as additional information for ' \
              'the object. Describe all your metadata fields.',
          sample_data_type: 'json' } # json_input / xml
      ]
    end,
    plan_search_output: lambda do |input|
      [
        { name: 'plans', type: 'array', of: 'object',
          properties: call('plan_schema', input) }
      ].
        concat([
                 { name: 'next_offset',
                   hint: 'This attribute is returned only if more resources are present. ' \
                     'To fetch the next set of resources use this value for the ' \
                     "input parameter 'offset'." }
               ])
    end,
    plan_get_input: lambda do
      [
        { name: 'id', label: 'Plan ID', optional: false },
        {
          name: 'schema_builder',
          extends_schema: true,
          control_type: 'schema-designer',
          label: 'Data fields',
          sticky: true,
          empty_schema_title: 'Describe all fields for your meta fields.',
          hint: 'A set of key-value pairs stored as additional information for ' \
                'the object. Describe all your metadata fields.',
          optional: true,
          sample_data_type: 'json' # json_input / xml
        }
      ]
    end,
    plan_get_output: lambda do |input|
      call('plan_schema', input)
    end,
    addon_schema: lambda do |input|
      call('plan_schema', input).
        ignored('applicable_addons',
                'attached_addons', 'event_based_addons', 'period_unit', 'trial_period',
                'trial_period_unit', 'free_quantity', 'setup_cost', 'billing_cycles',
                'redirect_url', 'enabled_in_hosted_pages', 'addon_applicability',
                'giftable', 'claim_url', 'free_quantity_in_decimal').
        concat([
                 { name: 'charge_type' },
                 { name: 'period_unit' },
                 { name: 'unit' },
                 { name: 'type' },
                 { name: 'included_in_mrr', label: 'Included in MRR',
                   type: 'boolean', control_type: 'checkbox',
                   convert_output: 'boolean_conversion' }
               ])
    end,
    addon_search_input: lambda do
      [
        { name: 'charge_type', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'period_string_field_types',
              extends_schema: true,
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                extends_schema:  true,
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'in', 'not_in'"
              } },
            { ngIf: 'input.charge_type.operator == "in" || input.charge_type.operator == "not_in"',
              name: 'value', type: 'string', sticky: true,
              control_type: 'multiselect', pick_list: 'charge_type',
              delimiter: ',',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'recurring', 'non_recurring'. Multiple " \
                      "values can be seperated using comma(','). e.g. recurring,non_recurring"
              } },
            { ngIf: '!(input.charge_type.operator == "in" || input.charge_type.operator == "not_in")',
              name: 'value', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'charge_type',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'recurring', 'non_recurring'"
              } }
          ] }
      ].
        concat(call('plan_search_input').
          ignored('trial_period', 'trial_period_unit',
                  'addon_applicability', 'giftable', 'meta_data')).
        concat([
                 { name: 'include_deleted',
                   type: 'boolean', control_type: 'checkbox',
                   convert_input: 'boolean_conversion',
                   toggle_hint: 'Select from list',
                   toggle_field: {
                     name: 'include_deleted',
                     label: 'Include deleted',
                     optional: true,
                     type: 'string', control_type: 'text',
                     convert_input: 'boolean_conversion',
                     toggle_hint: 'Use custom value',
                     hint: 'Allowed values are: true, false.'
                   } }
               ])
    end,
    addon_search_output: lambda do |input|
      [
        { name: 'addons', label: 'Add-ons', type: 'array', of: 'object',
          properties: call('addon_schema', input) }
      ].
        concat([
                 { name: 'next_offset',
                   hint: 'This attribute is returned only if more resources are present. ' \
                     'To fetch the next set of resources use this value for the ' \
                     "input parameter 'offset'." }
               ])
    end,
    addon_get_input: lambda do
      [
        { name: 'id', label: 'Addon ID', optional: false },
        {
          name: 'schema_builder',
          extends_schema: true,
          control_type: 'schema-designer',
          label: 'Data fields',
          sticky: true,
          empty_schema_title: 'Describe all fields for your meta fields.',
          hint: 'A set of key-value pairs stored as additional information for ' \
                'the addon. Describe all your metadata fields.',
          optional: true,
          sample_data_type: 'json' # json_input / xml
        }
      ]
    end,
    addon_get_output: lambda do |input|
      call('addon_schema', input)
    end,
    subscription_search_input: lambda do
      fields = [
        { name: 'include_deleted', sticky: true,
          type: 'boolean', control_type: 'checkbox',
          convert_input: 'boolean_conversion',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'include_deleted',
            label: 'Include deleted',
            optional: true, sticky: true,
            type: 'string', control_type: 'text',
            convert_input: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: true, false.'
          } },
        { name: 'sort_by', type: 'object', sticky: true,
          properties: [
            { name: 'value', label: 'Attribute',
              type: 'string', sticky: true,
              control_type: 'select', pick_list: 'attribute_list',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Attribute',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'created_at', 'updated_at'"
              } },
            { name: 'sort_order', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'sort_order_list',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'sort_order',
                label: 'Sort order',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'asc', 'desc'"
              } }
          ] },
        { name: 'customer_id', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'id_string_field_types',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'starts_with', 'in', 'not_in'"
              } },
            { name: 'value', sticky: true,
              hint: "Use comma(',') separated value for 'in' and 'not_in' operator. " \
                    'e.g. value1,value2' }
          ] },
        { name: 'plan_id', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'id_string_field_types',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'starts_with', 'in', 'not_in'"
              } },
            { name: 'value', sticky: true,
              hint: "Use comma(',') separated value for 'in' and 'not_in' operator. " \
                    'e.g. value1,value2' }
          ] },
        { name: 'status', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'period_string_field_types',
              extends_schema: true,
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                extends_schema: true,
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'in', 'not_in'"
              } },
            { ngIf: 'input.status.operator == "in" || input.status.operator == "not_in"',
              name: 'value', type: 'string', sticky: true,
              control_type: 'multiselect', pick_list: 'subscription_status',
              delimiter: ',',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'future', 'in_trial', 'active', " \
                      "'non_renewing', 'paused', 'cancelled'. Multiple values " \
                      "can be seperated using comma(','). e.g. future,in_trial"
              } },
            { ngIf: '!(input.status.operator == "in" || input.status.operator == "not_in")',
              name: 'value', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'subscription_status',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'future', 'in_trial', 'active', " \
                      "'non_renewing', 'paused', 'cancelled'"
              } }
          ] },
        { name: 'cancel_reason', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'subscription_string_filter_types',
              extends_schema: true,
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                extends_schema: true,
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'in', 'not_in', 'is_present'"
              } },
            { ngIf: 'input.cancel_reason.operator == "in" || input.cancel_reason.operator == "not_in"',
              name: 'value', type: 'string', sticky: true,
              control_type: 'multiselect', pick_list: 'cancel_reason_value',
              delimiter: ',',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'not_paid', 'no_card',
                      'fraud_review_failed', 'non_compliant_eu_customer',
                      'tax_calculation_failed', 'currency_incompatible_with_gateway',
                      'non_compliant_customer"
              } },
            { ngIf: 'input.cancel_reason.operator == "is_present"',
              name: 'value',
              hint: "If operator is 'is_present', allowed values are true/false" },
            { ngIf: '!(input.cancel_reason.operator == "in" || input.cancel_reason.operator == "not_in")',
              name: 'value', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'cancel_reason_value',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'not_paid', 'no_card',
                      'fraud_review_failed', 'non_compliant_eu_customer',
                      'tax_calculation_failed', 'currency_incompatible_with_gateway',
                      'non_compliant_customer"
              } }
          ] },
        { name: 'cancel_reason_code', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'id_string_field_types',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'starts_with', 'in', 'not_in'"
              } },
            { name: 'value', sticky: true,
              hint: "Use comma(',') separated value for 'in' and 'not_in' operator. " \
                    'e.g. value1,value2' }
          ] },
        { name: 'remaining_billing_cycles', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'trial_number_filter_types',
              extends_schema: true,
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                extends_schema: true,
                toggle_hint: 'Use custom value',
                hint: "Allowed values are  'is', 'is_not', 'lt', 'lte', 'gt', " \
                  "'gte', 'between', 'is_present'"
              } },
            { ngIf: 'input.remaining_billing_cycles.operator == "between"',
              name: 'from', type: 'integer', control_type: 'integer',
              convert_input: 'integer_conversion', sticky: true },
            { ngIf: 'input.remaining_billing_cycles.operator == "between"',
              name: 'to', type: 'integer', control_type: 'integer',
              convert_input: 'integer_conversion', sticky: true },
            { ngIf: 'input.remaining_billing_cycles.operator != "between"',
              name: 'value', type: 'integer', control_type: 'integer',
              convert_input: 'integer_conversion', sticky: true,
              hint: "If operator is 'is_present', allowed values are true/false" }
          ] },
        { name: 'created_at', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'timestamp_filter_types',
              extends_schema: true,
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                extends_schema: true,
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'after', 'before', 'on', 'between'"
              } },
            { ngIf: 'input.created_at.operator == "between"',
              name: 'from', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time',
              convert_output: 'render_iso8601_timestamp', sticky: true },
            { ngIf: 'input.created_at.operator == "between"',
              name: 'to', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time',
              convert_output: 'render_iso8601_timestamp', sticky: true },
            { ngIf: 'input.created_at.operator != "between"',
              name: 'value', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time',
              convert_output: 'render_iso8601_timestamp', sticky: true }
          ] },
        { name: 'activated_at', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'timestamp_filter_types',
              extends_schema: true,
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                extends_schema: true,
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'after', 'before', 'on', 'between'"
              } },
            { ngIf: 'input.activated_at.operator == "between"',
              name: 'from', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time',
              convert_output: 'render_iso8601_timestamp', sticky: true },
            { ngIf: 'input.activated_at.operator == "between"',
              name: 'to', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time',
              convert_output: 'render_iso8601_timestamp', sticky: true },
            { ngIf: 'input.activated_at.operator != "between"',
              name: 'value', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time',
              convert_output: 'render_iso8601_timestamp', sticky: true }
          ] },
        { name: 'cancelled_at', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'timestamp_filter_types',
              extends_schema: true,
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                extends_schema: true,
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'after', 'before', 'on', 'between'"
              } },
            { ngIf: 'input.cancelled_at.operator == "between"',
              name: 'from', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time',
              convert_output: 'render_iso8601_timestamp', sticky: true },
            { ngIf: 'input.cancelled_at.operator == "between"',
              name: 'to', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time',
              convert_output: 'render_iso8601_timestamp', sticky: true },
            { ngIf: 'input.cancelled_at.operator != "between"',
              name: 'value', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time',
              convert_output: 'render_iso8601_timestamp', sticky: true }
          ] },
        { name: 'next_billing_at', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'timestamp_filter_types',
              toggle_hint: 'Select from list',
              extends_schema: true,
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                extends_schema: true,
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'after', 'before', 'on', 'between'"
              } },
            { ngIf: 'input.next_billing_at.operator == "between"',
              name: 'from', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time',
              convert_output: 'render_iso8601_timestamp', sticky: true },
            { ngIf: 'input.next_billing_at.operator == "between"',
              name: 'to', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time',
              convert_output: 'render_iso8601_timestamp', sticky: true },
            { ngIf: 'input.next_billing_at.operator != "between"',
              name: 'value', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time',
              convert_output: 'render_iso8601_timestamp', sticky: true }
          ] },
        { name: 'has_scheduled_changes', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'boolean_filter_types',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed value: 'is'."
              } },
            { name: 'value',
              type: 'boolean', control_type: 'checkbox',
              convert_input: 'boolean_conversion',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value', label: 'Value',
                optional: true, sticky: true,
                type: 'string', control_type: 'text',
                convert_input: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true, false.'
              } }
          ] },
        { name: 'offline_payment_method', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'period_string_field_types',
              extends_schema: true,
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                extends_schema: true,
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'in', 'not_in'"
              } },
            { ngIf: 'input.offline_payment_method.operator == "in" || input.offline_payment_method.operator == "not_in"',
              name: 'value', type: 'string', sticky: true,
              control_type: 'multiselect', pick_list: 'offline_payment_method_list',
              delimiter: ',',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'no_preference', 'cash', 'check', " \
                      "'bank_transfer', 'ach_credit', 'sepa_credit'. Multiple " \
                      "values can be seperated using comma(','). e.g. cash,check"
              } },
            { ngIf: '!(input.offline_payment_method.operator == "in" || input.offline_payment_method.operator == "not_in")',
              name: 'value', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'offline_payment_method_list',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'no_preference', 'cash', 'check', " \
                      "'bank_transfer', 'ach_credit', 'sepa_credit'"
              } }
          ] },
        { name: 'auto_close_invoices', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'boolean_filter_types',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed value: 'is'."
              } },
            { name: 'value',
              type: 'boolean', control_type: 'checkbox',
              convert_input: 'boolean_conversion',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value', label: 'Value',
                optional: true, sticky: true,
                type: 'string', control_type: 'text',
                convert_input: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true, false.'
              } }
          ] },
        { name: 'override_relationship', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'boolean_filter_types',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed value: 'is'."
              } },
            { name: 'value',
              type: 'boolean', control_type: 'checkbox',
              convert_input: 'boolean_conversion',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value', label: 'Value',
                optional: true, sticky: true,
                type: 'string', control_type: 'text',
                convert_input: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true, false.'
              } }
          ] }
      ]
      fields.concat(call('plan_search_input').only('limit', 'offset', 'id',
                                                   'updated_at', 'schema_builder'))
    end,
    subscription_search_output: lambda do |input|
      [
        { name: 'subscriptions', type: 'array', of: 'object',
          properties: call('subscription_schema', input).
            concat([
                     { name: 'customer', type: 'object',
                       properties: call('customer_schema', input) },
                     { name: 'card', type: 'object',
                       properties: call('card_schema') }
                   ]) },
        { name: 'next_offset' }
      ]
    end,
    subscription_get_input: lambda do
      [
        { name: 'id', label: 'Subscription ID', optional: false },
        {
          name: 'schema_builder',
          extends_schema: true,
          control_type: 'schema-designer',
          label: 'Data fields',
          sticky: true,
          empty_schema_title: 'Describe all fields for your meta fields.',
          hint: 'A set of key-value pairs stored as additional information for ' \
                'the subscription. Describe all your metadata fields.',
          optional: true,
          sample_data_type: 'json' # json_input / xml
        }
      ]
    end,
    subscription_get_output: lambda do |input|
      call('subscription_schema', input).
        concat([
                 { name: 'customer', type: 'object',
                   properties: call('customer_schema', input) },
                 { name: 'card', type: 'object',
                   properties: call('card_schema') }
               ])
    end,
    credit_note_search_input: lambda do
      call('subscription_search_input').
        ignored('plan_id', 'cancel_reason', 'sort_by', 'schema_builder',
                'remaining_billing_cycles', 'created_at', 'activated_at',
                'cancelled_at', 'next_billing_at', 'has_scheduled_changes',
                'offline_payment_method', 'auto_close_invoices', 'create_pending_invoices',
                'override_relationship', 'status', 'cancel_reason_code').
        concat([
                 { name: 'subscription_id', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'subscription_id_string_field_types',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', 'in', 'not_in', " \
                               "'is_present', 'starts_with'"
                       } },
                     { name: 'value', sticky: true,
                       hint: "Use comma(',') separated value for 'in' and 'not_in' operator. " \
                             "e.g. value1,value2. If operator is 'is_present', allowed values are true/false" }
                   ] },
                 { name: 'reference_invoice_id', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'id_string_field_types',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', 'starts_with', 'in', 'not_in'"
                       } },
                     { name: 'value', sticky: true,
                       hint: "Use comma(',') separated value for 'in' and 'not_in' operator. " \
                             'e.g. value1,value2' }
                   ] },
                 { name: 'type', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'period_string_field_types',
                       toggle_hint: 'Select from list',
                       extends_schema: true,
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         extends_schema: true,
                         hint: "Allowed values are 'is', 'is_not', 'in', 'not_in'"
                       } },
                     { ngIf: 'input.type.operator == "in" || input.type.operator == "not_in"',
                       name: 'value', type: 'string', sticky: true,
                       control_type: 'multiselect', pick_list: 'credit_note_type_list',
                       delimiter: ',',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'value',
                         label: 'Value',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'adjustment', 'refundable'. " \
                               "Multiple values can be seperated using comma(','). e.g. adjustment,refundable"
                       } },
                     { ngIf: '!(input.type.operator == "in" || input.type.operator == "not_in")',
                       name: 'value', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'credit_note_type_list',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'value',
                         label: 'Value',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'adjustment', 'refundable'"
                       } }
                   ] },
                 { name: 'reason_code', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'period_string_field_types',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', 'in', 'not_in'"
                       } },
                     { ngIf: 'input.reason_code.operator == "in" || input.reason_code.operator == "not_in"',
                       name: 'value', type: 'string', sticky: true,
                       control_type: 'multiselect', pick_list: 'reason_code_list',
                       delimiter: ',',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'value',
                         label: 'Value',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'write_off', 'subscription_change', " \
                               "'subscription_cancellation', 'subscription_pause', 'chargeback', " \
                               "'product_unsatisfactory', 'service_unsatisfactory', 'order_change', " \
                               "'order_cancellation', 'waiver', 'other', 'fraudulent'. " \
                               "Multiple values can be seperated using comma(','). e.g. write_off,chargeback"
                       } },
                     { ngIf: '!(input.reason_code.operator == "in" || input.reason_code.operator == "not_in")',
                       name: 'value', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'reason_code_list',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'value',
                         label: 'Value',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'write_off', 'subscription_change', " \
                               "'subscription_cancellation', 'subscription_pause', 'chargeback', " \
                               "'product_unsatisfactory', 'service_unsatisfactory', 'order_change', " \
                               "'order_cancellation', 'waiver', 'other', 'fraudulent'"
                       } }
                   ] },
                 { name: 'status', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'period_string_field_types',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', 'in', 'not_in'"
                       } },
                     { ngIf: 'input.status.operator == "in" || input.status.operator == "not_in"',
                       name: 'value', type: 'string', sticky: true,
                       control_type: 'multiselect', pick_list: 'credit_note_status',
                       delimiter: ',',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'value',
                         label: 'Value',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'adjusted', 'refunded', 'refund_due', 'voided'. " \
                               "Multiple values can be seperated using comma(','). e.g. adjusted,refunded"
                       } },
                     { ngIf: '!(input.status.operator == "in" || input.status.operator == "not_in")',
                       name: 'value', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'credit_note_status',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'value',
                         label: 'Value',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'adjusted', 'refunded', 'refund_due', 'voided'"
                       } }
                   ] },
                 { name: 'date', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'timestamp_filter_types',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'after', 'before', 'on', 'between'"
                       } },
                     { ngIf: 'input.date.operator == "between"',
                       name: 'from', type: 'date_time', control_type: 'date_time',
                       convert_input: 'render_epoch_time',
                       convert_output: 'render_iso8601_timestamp', sticky: true },
                     { ngIf: 'input.date.operator == "between"',
                       name: 'to', type: 'date_time', control_type: 'date_time',
                       convert_input: 'render_epoch_time',
                       convert_output: 'render_iso8601_timestamp', sticky: true },
                     { ngIf: 'input.date.operator != "between"',
                       name: 'value', type: 'date_time', control_type: 'date_time',
                       convert_input: 'render_epoch_time',
                       convert_output: 'render_iso8601_timestamp', sticky: true }
                   ] },
                 { name: 'total', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'number_filter_types',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', 'lt', 'lte', 'gt', 'gte', 'between'"
                       } },
                     { ngIf: 'input.total.operator == "between"',
                       name: 'from', sticky: true,
                       type: 'number', control_type: 'number' },
                     { ngIf: 'input.total.operator == "between"',
                       name: 'to', sticky: true,
                       type: 'number', control_type: 'number' },
                     { ngIf: 'input.total.operator != "between"',
                       name: 'value', sticky: true,
                       type: 'number', control_type: 'number' }
                   ] },
                 { name: 'price_type', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'period_string_field_types',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', 'in', 'not_in'"
                       } },
                     { ngIf: 'input.price_type.operator == "in" || input.price_type.operator == "not_in"',
                       name: 'value', type: 'string', sticky: true,
                       control_type: 'multiselect', pick_list: 'price_type',
                       delimiter: ',',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'value',
                         label: 'Value',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'tax_inclusive', 'tax_exclusive'. " \
                               "Multiple values can be seperated using comma(','). e.g. tax_inclusive,tax_exclusive"
                       } },
                     { ngIf: '!(input.price_type.operator == "in" || input.price_type.operator == "not_in")',
                       name: 'value', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'price_type',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'value',
                         label: 'Value',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'tax_inclusive', 'tax_exclusive'"
                       } }
                   ] },
                 { name: 'amount_allocated', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'number_filter_types',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', 'lt', 'lte', 'gt', 'gte', 'between'"
                       } },
                     { ngIf: 'input.amount_allocated.operator == "between"',
                       name: 'from', sticky: true,
                       type: 'number', control_type: 'number' },
                     { ngIf: 'input.amount_allocated.operator == "between"',
                       name: 'to', sticky: true,
                       type: 'number', control_type: 'number' },
                     { ngIf: 'input.amount_allocated.operator != "between"',
                       name: 'value', sticky: true,
                       type: 'number', control_type: 'number' }
                   ] },
                 { name: 'amount_refunded', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'number_filter_types',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', 'lt', 'lte', 'gt', 'gte', 'between'"
                       } },
                     { ngIf: 'input.amount_refunded.operator == "between"',
                       name: 'from', sticky: true,
                       type: 'number', control_type: 'number' },
                     { ngIf: 'input.amount_refunded.operator == "between"',
                       name: 'to', sticky: true,
                       type: 'number', control_type: 'number' },
                     { ngIf: 'input.amount_refunded.operator != "between"',
                       name: 'value', sticky: true,
                       type: 'number', control_type: 'number' }
                   ] },
                 { name: 'amount_available', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'number_filter_types',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', 'lt', 'lte', 'gt', 'gte', 'between'"
                       } },
                     { ngIf: 'input.amount_available.operator == "between"',
                       name: 'from', sticky: true,
                       type: 'number', control_type: 'number' },
                     { ngIf: 'input.amount_available.operator == "between"',
                       name: 'to', sticky: true,
                       type: 'number', control_type: 'number' },
                     { ngIf: 'input.amount_available.operator != "between"',
                       name: 'value', sticky: true,
                       type: 'number', control_type: 'number' }
                   ] },
                 { name: 'sort_by', type: 'object', sticky: true,
                   properties: [
                     { name: 'value', label: 'Attribute',
                       type: 'string', sticky: true,
                       control_type: 'select', pick_list: [%w[Date date]],
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'value',
                         label: 'Attribute',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'date'"
                       } },
                     { name: 'sort_order', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'sort_order_list',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'sort_order',
                         label: 'Sort order',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'asc', 'desc'"
                       } }
                   ] },
                 { name: 'voided_at', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'timestamp_filter_types',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'after', 'before', 'on', 'between'"
                       } },
                     { ngIf: 'input.voided_at.operator == "between"',
                       name: 'from', type: 'date_time', control_type: 'date_time',
                       convert_input: 'render_epoch_time',
                       convert_output: 'render_iso8601_timestamp', sticky: true },
                     { ngIf: 'input.voided_at.operator == "between"',
                       name: 'to', type: 'date_time', control_type: 'date_time',
                       convert_input: 'render_epoch_time',
                       convert_output: 'render_iso8601_timestamp', sticky: true },
                     { ngIf: 'input.voided_at.operator != "between"',
                       name: 'value', type: 'date_time', control_type: 'date_time',
                       convert_input: 'render_epoch_time',
                       convert_output: 'render_iso8601_timestamp', sticky: true }
                   ] },
                 { name: 'create_reason_code', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'id_string_field_types',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', 'starts_with', 'in', 'not_in'"
                       } },
                     { name: 'value', sticky: true,
                       hint: "Use comma(',') separated value for 'in' and 'not_in' operator. " \
                             'e.g. value1,value2' }
                   ] }
               ])
    end,
    credit_note_search_output: lambda do |_input|
      [
        { name: 'credit_notes', type: 'array', of: 'object',
          properties: call('credit_note_schema') }
      ].
        concat([
                 { name: 'next_offset',
                   hint: 'This attribute is returned only if more resources are present. ' \
                     'To fetch the next set of resources use this value for the ' \
                     "input parameter 'offset'." }
               ])
    end,
    credit_note_get_input: lambda do
      [
        { name: 'id', label: 'Credit note ID', optional: false }
      ]
    end,
    credit_note_get_output: lambda do |_input|
      call('credit_note_schema')
    end,
    transaction_search_input: lambda do
      call('plan_search_input').
        only('limit', 'offset', 'id', 'updated_at').
        concat([
                 { name: 'include_deleted', sticky: true,
                   type: 'boolean', control_type: 'checkbox',
                   convert_input: 'boolean_conversion',
                   toggle_hint: 'Select from list',
                   toggle_field: {
                     name: 'include_deleted',
                     label: 'Include deleted',
                     optional: true, sticky: true,
                     type: 'string', control_type: 'text',
                     convert_input: 'boolean_conversion',
                     toggle_hint: 'Use custom value',
                     hint: 'Allowed values are: true, false.'
                   } },
                 { name: 'customer_id', type: 'object',
                   hint: 'Identifier of the customer with whom this' \
                     ' subscription is associated.',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'subscription_id_string_field_types',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', 'starts_with', 'in'" \
                           ", 'not_in', 'is_present'"
                       } },
                     { name: 'value', sticky: true,
                       hint: "Use comma(',') separated value for 'in' and 'not_in' operator. " \
                             "e.g. value1,value2. If operator is 'is_present', allowed values are true/false" }
                   ] },
                 { name: 'subscription_id', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'subscription_id_string_field_types',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', 'in', 'not_in', " \
                           "'is_present', 'starts_with'"
                       } },
                     { name: 'value', sticky: true,
                       hint: "Use comma(',') separated value for 'in' and 'not_in' operator. " \
                             "e.g. value1,value2. If operator is 'is_present', allowed values are true/false" }
                   ] },
                 { name: 'payment_source_id', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'subscription_id_string_field_types',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', 'in', 'not_in', " \
                           "'is_present', 'starts_with'"
                       } },
                     { name: 'value', sticky: true,
                       hint: "Use comma(',') separated value for 'in' and 'not_in' operator. " \
                             "e.g. value1,value2. If operator is 'is_present', allowed values are true/false" }
                   ] },
                 { name: 'payment_method', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'period_string_field_types',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', 'in', 'not_in'"
                       } },
                     { ngIf: 'input.payment_method.operator == "in" || input.payment_method.operator == "not_in"',
                       name: 'value', type: 'string', sticky: true,
                       control_type: 'multiselect', pick_list: 'payment_method_list',
                       delimiter: ',',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'value',
                         label: 'Value',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: 'Type of payment source. e.g. <b>card<b> for Card. ' \
                               "Multiple values can be separated using comma(','). e.g. value1,value2"
                       } },
                     { ngIf: '!(input.payment_method.operator == "in" || input.payment_method.operator == "not_in")',
                       name: 'value', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'payment_method_list',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'value',
                         label: 'Value',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: 'Type of payment source.' \
                           ' e.g. <b>card<b> for Card.'
                       } }
                   ] },
                 { name: 'gateway', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'period_string_field_types',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', 'in', 'not_in'"
                       } },
                     { ngIf: 'input.gateway.operator == "in" || input.gateway.operator == "not_in"',
                       name: 'value', type: 'string', sticky: true,
                       control_type: 'multiselect',
                       delimiter: ',',
                       pick_list: 'payment_method_gateway_list',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'value',
                         label: 'Value',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: 'Type of payment gateway. e.g. <b>WePay<b> for WePay payments.' \
                               "Multiple values can be seperated using comma(','). e.g. value1,value2"
                       } },
                     { ngIf: '!(input.gateway.operator == "in" || input.gateway.operator == "not_in")',
                       name: 'value', type: 'string', sticky: true,
                       control_type: 'select',
                       pick_list: 'payment_method_gateway_list',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'value',
                         label: 'Value',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: 'Type of payment gateway.' \
                           ' e.g. <b>WePay<b> for WePay payments.'
                       } }
                   ] },
                 { name: 'gateway_account_id', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'id_string_field_types',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', 'starts_with'," \
                           " 'in', 'not_in'"
                       } },
                     { name: 'value', sticky: true,
                       hint: "Use comma(',') separated value for 'in' and 'not_in' operator. " \
                             'e.g. value1,value2' }
                   ] },
                 { name: 'id_at_gateway', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'gateway_string_field_types',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', 'starts_with'"
                       } },
                     { name: 'value', type: 'string', sticky: true }
                   ] },
                 { name: 'reference_number', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'string_filter_types',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', 'starts_with'," \
                           " 'is_present'"
                       } },
                     { name: 'value', type: 'string', sticky: true,
                       hint: "If operator is 'is_present', allowed values are true/false" }
                   ] },
                 { name: 'type', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'period_string_field_types',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', 'in', 'not_in'"
                       } },
                     { ngIf: 'input.type.operator == "in" || input.type.operator == "not_in"',
                       name: 'value', type: 'string', sticky: true,
                       control_type: 'multiselect',
                       delimiter: ',',
                       pick_list: 'type_list',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'value',
                         label: 'Value',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'authorization', 'payment', " \
                           "'refund', 'payment_reversal'. Multiple values can " \
                           "be seperated using comma(','). e.g. payment,refund"
                       } },
                     { ngIf: '!(input.type.operator == "in" || input.type.operator == "not_in")',
                       name: 'value', type: 'string', sticky: true,
                       control_type: 'select',
                       pick_list: 'type_list',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'value',
                         label: 'Value',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'authorization', 'payment'," \
                           " 'refund', 'payment_reversal'"
                       } }
                   ] },
                 { name: 'date', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'timestamp_filter_types',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'after', 'before', 'on', 'between'"
                       } },
                     { ngIf: 'input.date.operator == "between"',
                       name: 'from', type: 'date_time', control_type: 'date_time',
                       convert_input: 'render_epoch_time',
                       convert_output: 'render_iso8601_timestamp', sticky: true },
                     { ngIf: 'input.date.operator == "between"',
                       name: 'to', type: 'date_time', control_type: 'date_time',
                       convert_input: 'render_epoch_time',
                       convert_output: 'render_iso8601_timestamp', sticky: true },
                     { ngIf: 'input.date.operator != "between"',
                       name: 'value', type: 'date_time', control_type: 'date_time',
                       convert_input: 'render_epoch_time',
                       convert_output: 'render_iso8601_timestamp', sticky: true }
                   ] },
                 { name: 'amount', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'number_filter_types',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', 'lt', 'lte', 'gt', 'gte', 'between'"
                       } },
                     { ngIf: 'input.amount.operator == "between"',
                       name: 'from', sticky: true,
                       type: 'number', control_type: 'number' },
                     { ngIf: 'input.amount.operator == "between"',
                       name: 'to', sticky: true,
                       type: 'number', control_type: 'number' },
                     { ngIf: 'input.amount.operator != "between"',
                       name: 'value', sticky: true,
                       type: 'number', control_type: 'number' }
                   ] },
                 { name: 'amount_capturable', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'number_filter_types',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', 'lt', 'lte', 'gt', 'gte', 'between'"
                       } },
                     { ngIf: 'input.amount_capturable.operator == "between"',
                       name: 'from', sticky: true,
                       type: 'number', control_type: 'number' },
                     { ngIf: 'input.amount_capturable.operator == "between"',
                       name: 'to', sticky: true,
                       type: 'number', control_type: 'number' },
                     { ngIf: 'input.amount_capturable.operator != "between"',
                       name: 'value', sticky: true,
                       type: 'number', control_type: 'number' }
                   ] },
                 { name: 'sort_by', type: 'object', sticky: true,
                   properties: [
                     { name: 'value', label: 'Attribute',
                       type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'invoice_attribute_list',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'value',
                         label: 'Attribute',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'date', 'updated_at'"
                       } },
                     { name: 'sort_order', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'sort_order_list',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'sort_order',
                         label: 'Sort order',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'asc', 'desc'"
                       } }
                   ] },
                 { name: 'status', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'period_string_field_types',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', 'in', 'not_in'"
                       } },
                     { ngIf: 'input.status.operator == "in" || input.status.operator == "not_in"',
                       name: 'value', type: 'string', sticky: true,
                       control_type: 'multiselect', pick_list: 'transaction_status_value',
                       delimiter: ',',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'value', label: 'Value',
                         optional: true, sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'in_progress', 'voided', " \
                               "'failure', 'success', 'needs_attention', 'timeout'. " \
                               "Multiple values can be seperated using comma(','). e.g. voided,success"
                       } },
                     { ngIf: '!(input.status.operator == "in" || input.status.operator == "not_in")',
                       name: 'value', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'transaction_status_value',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'value', label: 'Value',
                         optional: true, sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'in_progress', 'voided', " \
                               "'failure', 'success', 'needs_attention', 'timeout'"
                       } }
                   ] }
               ])
    end,
    transaction_search_output: lambda do |_input|
      [
        { name: 'transactions', type: 'array', of: 'object',
          properties: call('transaction_schema') },
        { name: 'next_offset' }
      ]
    end,
    transaction_get_input: lambda do
      [
        { name: 'id', label: 'Transaction ID', optional: false }
      ]
    end,
    transaction_get_output: lambda do |_input|
      call('transaction_schema')
    end,
    invoice_payments_search_input: lambda do
      [
        { name: 'limit', sticky: true,
          type: 'integer', control_type: 'integer',
          convert_input: 'integer_conversion',
          hint: 'The number of resources to be returned. ' \
            'Default value is 10 and Maximum is 100' },
        { name: 'offset', sticky: true,
          hint: 'Determines your position in the list for pagination. To ensure ' \
            'that the next page is retrieved correctly, always set offset ' \
            'to the value of next_offset obtained in the previous ' \
            'iteration of the API call.' },
        { name: 'invoice_id', optional: false }
      ]
    end,
    invoice_payments_search_output: lambda do |input|
      call('transaction_search_output', input)
    end,
    advance_invoice_get_input: lambda do
      [
        { name: 'id', label: 'Subscription ID', optional: false }
      ]
    end,
    advance_invoice_get_output: lambda do |_input|
      [
        { name: 'advance_invoice_schedules', type: 'array', of: 'object',
          properties: [
            { name: 'id' },
            { name: 'object' },
            { name: 'schedule_type' },
            { name: 'fixed_interval_schedule', type: 'object',
              properties: [
                { name: 'end_schedule_on' },
                { name: 'number_of_occurrences', type: 'integer',
                  control_type: 'integer',
                  convert_output: 'integer_conversion' },
                { name: 'days_before_renewal', type: 'integer',
                  control_type: 'integer',
                  convert_output: 'integer_conversion' },
                { name: 'end_date', type: 'date_time', control_type: 'date_time',
                  convert_output: 'render_iso8601_timestamp' },
                { name: 'created_at', type: 'date_time', control_type: 'date_time',
                  convert_output: 'render_iso8601_timestamp' },
                { name: 'terms_to_charge', type: 'integer',
                  control_type: 'integer',
                  convert_output: 'integer_conversion' }
              ] },
            { name: 'specific_dates_schedule', type: 'object',
              properties: [
                { name: 'date', type: 'date_time', control_type: 'date_time',
                  convert_output: 'render_iso8601_timestamp' },
                { name: 'object' },
                { name: 'terms_to_charge', type: 'integer',
                  control_type: 'number', convert_output: 'integer_conversion' }
              ] }
          ] }
      ]
    end,
    invoice_search_input: lambda do
      call('subscription_search_input').
        ignored('plan_id', 'cancel_reason',
                'cancel_reason_code', 'remaining_billing_cycles', 'created_at',
                'activated_at', 'cancelled_at', 'next_billing_at', 'status',
                'has_scheduled_changes', 'offline_payment_method', 'auto_close_invoices',
                'create_pending_invoices', 'override_relationship', 'sort_by', 'schema_builder').
        concat([
                 { name: 'recurring', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'boolean_filter_types',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values is 'is'"
                       } },
                     { name: 'value',
                       type: 'boolean', control_type: 'checkbox',
                       convert_input: 'boolean_conversion',
                       toggle_hint: 'Select from list',
                       sticky: true,
                       toggle_field: {
                         name: 'value', label: 'Value',
                         optional: true, sticky: true,
                         type: 'string', control_type: 'text',
                         convert_input: 'boolean_conversion',
                         toggle_hint: 'Use custom value',
                         hint: 'Allowed values are: true, false.'
                       } }
                   ] },
                 { name: 'subscription_id', type: 'object',
                   hint: 'The display name used in web interface for identifying the subscription.',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'subscription_id_string_field_types',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', " \
                               "'starts_with', 'is_present', 'in', 'not_in'"
                       } },
                     { name: 'value', sticky: true,
                       hint: "Use comma(',') separated value for 'in' and 'not_in' operator. " \
                             "e.g. value1,value. If operator is 'is_present', allowed values are true/false" }
                   ] },
                 { name: 'price_type', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'period_string_field_types',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', 'in', 'not_in'"
                       } },
                     { ngIf: 'input.price_type.operator == "in" || input.price_type.operator == "not_in"',
                       name: 'value', type: 'string', sticky: true,
                       control_type: 'multiselect', pick_list: 'price_type',
                       delimiter: ',',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'value',
                         label: 'Value',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'tax_exclusive', 'tax_inclusive'. " \
                               "Multiple values can be seperated using comma(','). " \
                               'e.g. tax_inclusive,tax_exclusive'
                       } },
                     { ngIf: '!(input.price_type.operator == "in" || input.price_type.operator == "not_in")',
                       name: 'value', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'price_type',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'value',
                         label: 'Value',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'tax_exclusive', 'tax_inclusive'"
                       } }
                   ] },
                 { name: 'date', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'timestamp_filter_types',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'after', 'between', 'on', 'before'"
                       } },
                     { ngIf: 'input.date.operator == "between"',
                       name: 'from', type: 'date_time', control_type: 'date_time',
                       convert_input: 'render_epoch_time',
                       convert_output: 'render_iso8601_timestamp', sticky: true },
                     { ngIf: 'input.date.operator == "between"',
                       name: 'to', type: 'date_time', control_type: 'date_time',
                       convert_input: 'render_epoch_time',
                       convert_output: 'render_iso8601_timestamp', sticky: true },
                     { ngIf: 'input.date.operator != "between"',
                       name: 'value', type: 'date_time', control_type: 'date_time',
                       convert_input: 'render_epoch_time',
                       convert_output: 'render_iso8601_timestamp', sticky: true }
                   ] },
                 { name: 'status', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'period_string_field_types',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', 'in', 'not_in'"
                       } },
                     { ngIf: 'input.status.operator == "in" || input.status.operator == "not_in"',
                       name: 'value', type: 'string', sticky: true,
                       control_type: 'multiselect', pick_list: 'invoice_status',
                       delimiter: ',',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'value',
                         label: 'Value',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'paid', 'posted', " \
                               "'payment_due', 'not_paid', 'voided', 'pending'. " \
                               "Multiple values can be seperated using comma(','). " \
                               'e.g. paid,posted'
                       } },
                     { ngIf: '!(input.status.operator == "in" || input.status.operator == "not_in")',
                       name: 'value', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'invoice_status',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'value',
                         label: 'Value',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'paid', 'posted', " \
                               "'payment_due', 'not_paid', 'voided', 'pending'"
                       } }
                   ] },
                 { name: 'paid_at', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'timestamp_filter_types',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'after', 'between', 'on', 'before'"
                       } },
                     { ngIf: 'input.paid_at.operator == "between"',
                       name: 'from', type: 'date_time', control_type: 'date_time',
                       convert_input: 'render_epoch_time',
                       convert_output: 'render_iso8601_timestamp', sticky: true },
                     { ngIf: 'input.paid_at.operator == "between"',
                       name: 'to', type: 'date_time', control_type: 'date_time',
                       convert_input: 'render_epoch_time',
                       convert_output: 'render_iso8601_timestamp', sticky: true },
                     { ngIf: 'input.paid_at.operator != "between"',
                       name: 'value', type: 'date_time', control_type: 'date_time',
                       convert_input: 'render_epoch_time',
                       convert_output: 'render_iso8601_timestamp', sticky: true }
                   ] },
                 { name: 'total', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'number_filter_types',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', 'lt', " \
                               "'lte', 'gt', 'gte', 'between'"
                       } },
                     { ngIf: 'input.total.operator == "between"',
                       name: 'from', sticky: true,
                       type: 'number', control_type: 'number' },
                     { ngIf: 'input.total.operator == "between"',
                       name: 'to', sticky: true,
                       type: 'number', control_type: 'number' },
                     { ngIf: 'input.total.operator != "between"',
                       name: 'value', sticky: true,
                       type: 'number', control_type: 'number' }
                   ] },
                 { name: 'amount_paid', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'number_filter_types',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', 'lt', " \
                               "'lte', 'gt', 'gte', 'between'"
                       } },
                     { ngIf: 'input.amount_paid.operator == "between"',
                       name: 'from', sticky: true,
                       type: 'number', control_type: 'number' },
                     { ngIf: 'input.amount_paid.operator == "between"',
                       name: 'to', sticky: true,
                       type: 'number', control_type: 'number' },
                     { ngIf: 'input.amount_paid.operator != "between"',
                       name: 'value', sticky: true,
                       type: 'number', control_type: 'number' }
                   ] },
                 { name: 'amount_adjusted', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'number_filter_types',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', 'lt', " \
                               "'lte', 'gt', 'gte', 'between'"
                       } },
                     { ngIf: 'input.amount_adjusted.operator == "between"',
                       name: 'from', sticky: true,
                       type: 'number', control_type: 'number' },
                     { ngIf: 'input.amount_adjusted.operator == "between"',
                       name: 'to', sticky: true,
                       type: 'number', control_type: 'number' },
                     { ngIf: 'input.amount_adjusted.operator != "between"',
                       name: 'value', sticky: true,
                       type: 'number', control_type: 'number' }
                   ] },
                 { name: 'credits_applied', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'number_filter_types',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', 'lt', " \
                               "'lte', 'gt', 'gte', 'between'"
                       } },
                     { ngIf: 'input.credits_applied.operator == "between"',
                       name: 'from', sticky: true,
                       type: 'number', control_type: 'number' },
                     { ngIf: 'input.credits_applied.operator == "between"',
                       name: 'to', sticky: true,
                       type: 'number', control_type: 'number' },
                     { ngIf: 'input.credits_applied.operator != "between"',
                       name: 'value', sticky: true,
                       type: 'number', control_type: 'number' }
                   ] },
                 { name: 'amount_due', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'number_filter_types',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', 'lt', " \
                               "'lte', 'gt', 'gte', 'between'"
                       } },
                     { ngIf: 'input.amount_due.operator == "between"',
                       name: 'from', sticky: true,
                       type: 'number', control_type: 'number' },
                     { ngIf: 'input.amount_due.operator == "between"',
                       name: 'to', sticky: true,
                       type: 'number', control_type: 'number' },
                     { ngIf: 'input.amount_due.operator != "between"',
                       name: 'value', sticky: true,
                       type: 'number', control_type: 'number' }
                   ] },
                 { name: 'dunning_status', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'dunning_string_field_types',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', " \
                               "'is_present', 'in', 'not_in'"
                       } },
                     { ngIf: 'input.dunning_status.operator == "in" || input.dunning_status.operator == "not_in"',
                       name: 'value', type: 'string', sticky: true,
                       control_type: 'multiselect', pick_list: 'dunning_status_value',
                       delimiter: ',',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'value',
                         label: 'Value',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'in_progress', " \
                               "'exhausted', 'stopped', 'success'. Multiple values " \
                               "can be seperated using comma(','). e.g. in_progress,stopped"
                       } },
                     { ngIf: 'input.dunning_status.operator == "is_present"',
                       name: 'value', hint: "If operator is 'is_present', allowed values are true/false" },
                     { ngIf: '!(input.dunning_status.operator == "in" || input.dunning_status.operator == "not_in")',
                       name: 'value', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'dunning_status_value',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'value',
                         label: 'Value',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'in_progress', " \
                               "'exhausted', 'stopped', 'success'"
                       } }
                   ] },
                 { name: 'payment_owner', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'id_string_field_types',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', " \
                               "'starts_with', 'in', 'not_in'"
                       } },
                     { name: 'value', sticky: true,
                       hint: "Use comma(',') separated value for 'in' and 'not_in' operator. " \
                             'e.g. value1,value2' }
                   ] },
                 { name: 'voided_at', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'timestamp_filter_types',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'after', 'between', 'on', 'before'"
                       } },
                     { ngIf: 'input.voided_at.operator == "between"',
                       name: 'from', type: 'date_time', control_type: 'date_time',
                       convert_input: 'render_epoch_time',
                       convert_output: 'render_iso8601_timestamp', sticky: true },
                     { ngIf: 'input.voided_at.operator == "between"',
                       name: 'to', type: 'date_time', control_type: 'date_time',
                       convert_input: 'render_epoch_time',
                       convert_output: 'render_iso8601_timestamp', sticky: true },
                     { ngIf: 'input.voided_at.operator != "between"',
                       name: 'value', type: 'date_time', control_type: 'date_time',
                       convert_input: 'render_epoch_time',
                       convert_output: 'render_iso8601_timestamp', sticky: true }
                   ] },
                 { name: 'void_reason_code', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'id_string_field_types',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', " \
                               "'starts_with', 'in', 'not_in'"
                       } },
                     { name: 'value', sticky: true,
                       hint: "Use comma(',') separated value for 'in' and 'not_in' operator. " \
                             'e.g. value1,value2' }
                   ] },
                 { name: 'sort_by', type: 'object', sticky: true,
                   properties: [
                     { name: 'value', label: 'Attribute',
                       type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'invoice_attribute_list',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'value',
                         label: 'Attribute',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'date', 'updated_at'"
                       } },
                     { name: 'sort_order', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'sort_order_list',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'sort_order',
                         label: 'Sort order',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'asc', 'desc'"
                       } }
                   ] },
                 { name: 'channel', type: 'object',
                   properties: [
                     { name: 'operator', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'period_string_field_types',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'operator',
                         label: 'Operator',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'is', 'is_not', 'in', 'not_in'"
                       } },
                     { ngIf: 'input.channel.operator == "in" || input.channel.operator == "not_in"',
                       name: 'value', type: 'string', sticky: true,
                       control_type: 'multiselect', pick_list: 'channel_type',
                       delimiter: ',',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'value',
                         label: 'Value',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'app_store', 'play_store'. " \
                               "Multiple values can be seperated using comma(','). e.g. one_time,forever"
                       } },
                     { ngIf: '!(input.channel.operator == "in" || input.channel.operator == "not_in")',
                       name: 'value', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'channel_type',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'value',
                         label: 'Value',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'app_store', 'play_store'."
                       } }
                   ] },
               ])
    end,
    invoice_search_output: lambda do |_input|
      [
        { name: 'invoices', type: 'array', of: 'object',
          properties: call('invoice_schema', '').ignored('payment_intent') },
        { name: 'next_offset' }
      ]
    end,
    invoice_get_input: lambda do
      [
        { name: 'id', label: 'Invoice ID', optional: false }
      ]
    end,
    invoice_get_output: lambda do |_input|
      call('invoice_schema', '')
    end,
    customer_create_input: lambda do |input|
      call('customer_schema', input).
        ignored('referral_urls', 'contacts', 'balances', 'relationship',
                'parent_account_access', 'child_account_access', 'created_at', 'updated_at').
        concat([
                 { name: 'taxjar_exemption_category',
                   hint: 'Indicates the exemption type of the customer.' \
                     ' This is applicable only if you use Chargebee’s' \
                     ' TaxJar integration.',
                   control_type: 'select', pick_list: 'taxjar',
                   toggle_hint: 'Select from list',
                   toggle_field: {
                     name: 'taxjar_exemption_category',
                     label: 'Taxjar exemption category',
                     optional: true,
                     sticky: true,
                     type: 'string',
                     control_type: 'text',
                     toggle_hint: 'Use custom value',
                     hint: "Allowed values are 'wholesale'," \
                       " 'government', 'other'"
                   } },
                 { name: 'token_id',
                   hint: 'The Chargebee payment token generated by Chargebee JS.' },
                 { name: 'card', type: 'object', properties:
                   call('card_schema').
                     only('gateway_account_id', 'first_name', 'last_name', 'expiry_month',
                          'expiry_year', 'billing_addr1', 'billing_addr2', 'billing_city',
                          'billing_state_code', 'billing_state', 'billing_zip', 'billing_country').
                     concat([
                              { name: 'number', label: 'Card number',
                                optional: false,
                                hint: 'The credit card number without any format. If you are using' \
                                      ' Braintree.js, you can specify the Braintree ' \
                                      'encrypted card number here.' },
                              { name: 'cvv', label: 'Card verification value(cvv)',
                                optional: false,
                                hint: 'The card verification value (CVV). ' \
                                      'If you are using Braintree.js,' \
                                      ' you can specify the Braintree encrypted CVV here.' },
                              { name: 'additional_information' }
                            ]) },
                 { name: 'bank_account', type: 'object',
                   properties: [
                     { name: 'gateway_account_id',
                       hint: 'The gateway account in which this payment source is stored.' },
                     { name: 'iban', label: 'International bank account number' },
                     { name: 'first_name' },
                     { name: 'last_name' },
                     { name: 'company' },
                     { name: 'email' },
                     { name: 'bank_name' },
                     { name: 'account_number' },
                     { name: 'routing_number' },
                     { name: 'bank_code' },
                     { name: 'account_type', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'account_type',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'account_type',
                         label: 'Account type',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'checking', 'savings', 'business_checking'"
                       } },
                     { name: 'account_holder_type', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'account_holder_type',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'account_holder_type',
                         label: 'Account holder type',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'individual', 'company'"
                       } },
                     { name: 'echeck_type', type: 'string', sticky: true, label: 'E-check type',
                       control_type: 'select', pick_list: 'echeck_type',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'echeck_type',
                         label: 'E-check type',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'web', 'ppd', 'ccd'"
                       } },
                     { name: 'issuing_country' },
                     { name: 'swedish_identity_number' },
                     { name: 'billing_address', type: 'object',
                       properties: call('business_address_schema', '') }
                   ] },
                 { name: 'payment_intent', type: 'object', properties: [
                   { name: 'id', label: 'Payment intent ID',
                     hint: 'Payment intent ID generated by Chargebee.js' },
                   { name: 'gateway_account_id',
                     hint: 'Gateway account used for performing the 3DS flow.' },
                   { name: 'gw_token', label: 'Gateway token',
                     hint: 'Identifier for 3DS transaction/verification object at the gateway.' },
                   { name: 'reference_id',
                     hint: 'Identifier for Braintree permanent token. Applicable when you are' \
                       ' using Braintree APIs for completing the 3DS flow.' },
                   { name: 'additional_info', label: 'Additional information',
                     hint: 'Pass a stringified JSON. For E.g: click <a href=' \
                       "'https://apidocs.chargebee.com/docs/api/payment_parameters" \
                       "#payment_intent_additonal_info_sample'>" \
                       'here<a> to see sample json.' }
                 ] },
                 { name: 'schema_builder',
                   extends_schema: true,
                   control_type: 'schema-designer',
                   label: 'Data fields',
                   sticky: true,
                   empty_schema_title: 'Describe all fields for your metadata fields.',
                   optional: true,
                   hint: 'A set of key-value pairs stored as additional information for ' \
                       'the object. Describe all your metadata fields.',
                   sample_data_type: 'json' }
               ])
    end,
    comment_create_input: lambda do |_input|
      [
        { name: 'entity_type', type: 'string', optional: false,
          control_type: 'select', pick_list: 'comment_entity_type',
          hint: 'Type of the entity to create the comment for.',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'entity_type', label: 'Entity type',
            optional: false, sticky: true,
            type: 'string', control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: "Type of the entity to create the comment for. Allowed " \
                  "values are 'customer', 'subscription', 'coupon', " \
                  "'invoice', 'quote', 'credit_note', 'transaction', 'plan', " \
                  "'addon', 'order', 'item_family', 'item', 'item_price'"
          } },
        { name: 'entity_id', optional: false,
          hint: 'Unique identifier of the entity.' },
        { name: 'notes', optional: false,
          hint: 'Actual notes for the comment.' },
        { name: 'added_by', sticky: true,
          hint: 'The user who created the comment. If created via API, this ' \
                'contains the name given for the API key used.' }
      ]
    end,
    invoice_charge_create_input: lambda do |_input|
        [
          { name: 'customer_id', sticky: true,
            hint: 'Identifier of the customer for which this invoice needs to be created. ' \
                  'Should be specified if subscription_id is not specified.' },
          { name: 'subscription_id', sticky: true,
            hint: 'Identifier of the subscription for which this invoice needs to be created. ' \
                  'Should be specified if customer_id is not specified.(not applicable ' \
                  'for consolidated invoice).' },
          { name: 'amount', sticky: true, 
            hint: 'The amount to be charged in cents, min=1. The unit depends on the type of currency.',
            type: 'number', control_type: 'number', 
            label: 'Amount (in cents)' },
          { name: 'date_from', sticky: true, type: 'date_time', control_type: 'date_time',
            convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp',
            label: 'Date from' },
          { name: 'date_to', sticky: true, type: 'date_time', control_type: 'date_time',
            convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp',
            label: 'Date to' },
          { name: 'description', sticky: true}
        ]
    end,
    invoice_create_input: lambda do |_input|
      call('invoice_schema', '').ignored('id', 'notes').
        concat([
                 { name: 'card', type: 'object',
                   properties: [
                     { name: 'gateway_account_id',
                       hint: 'The gateway account in which this payment source is stored.' },
                     { name: 'first_name', hint: 'Cardholders first name.' },
                     { name: 'last_name', hint: 'Cardholders last name.' },
                     { name: 'number',
                       hint: 'The credit card number without any format. If you are using ' \
                             'Braintree.js, you can specify the Braintree encrypted card ' \
                             'number here. Required if card provided' },
                     { name: 'expiry_month', type: 'integer', control_type: 'integer',
                       convert_input: 'integer_conversion',
                       convert_output: 'integer_conversion',
                       hint: 'Card expiry month. Required if card provided' },
                     { name: 'expiry_year', type: 'integer', control_type: 'integer',
                       convert_input: 'integer_conversion',
                       convert_output: 'integer_conversion',
                       hint: 'Card expiry year. Required if card provided' },
                     { name: 'cvv', label: 'Card verification value',
                       hint: 'The card verification value (CVV). If you are using Braintree.js, ' \
                             'you can specify the Braintree encrypted CVV here.' },
                     { name: 'billing_addr1', label: 'Address line 1' },
                     { name: 'billing_addr2', label: 'Address line 2' },
                     { name: 'billing_city' },
                     { name: 'billing_state_code' },
                     { name: 'billing_state' },
                     { name: 'billing_zip' },
                     { name: 'billing_country' },
                     { name: 'additional_information' }
                   ] },
                 { name: 'bank_account', type: 'object',
                   properties: [
                     { name: 'gateway_account_id',
                       hint: 'The gateway account in which this payment source is stored.' },
                     { name: 'iban', label: 'International bank account number' },
                     { name: 'first_name' },
                     { name: 'last_name' },
                     { name: 'company' },
                     { name: 'email' },
                     { name: 'bank_name' },
                     { name: 'account_number' },
                     { name: 'routing_number' },
                     { name: 'bank_code' },
                     { name: 'account_type', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'account_type',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'account_type',
                         label: 'Account type',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'checking', 'savings', 'business_checking'"
                       } },
                     { name: 'account_holder_type', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'account_holder_type',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'account_holder_type',
                         label: 'Account holder type',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'individual', 'company'"
                       } },
                     { name: 'echeck_type', type: 'string', sticky: true, label: 'E-check type',
                       control_type: 'select', pick_list: 'echeck_type',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'echeck_type',
                         label: 'E-check type',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'web', 'ppd', 'ccd'"
                       } },
                     { name: 'issuing_country' },
                     { name: 'swedish_identity_number' },
                     { name: 'billing_address', type: 'object',
                       properties: call('business_address_schema', '') }
                   ] },
                 { name: 'addons', type: 'array', of: 'object',
                   properties: [
                     { name: 'id' },
                     { name: 'quantity', type: 'integer', control_type: 'integer',
                       convert_output: 'integer_conversion' },
                     { name: 'unit_price', type: 'number', control_type: 'number' },
                     { name: 'quantity_in_decimal' },
                     { name: 'unit_price_in_decimal' },
                     { name: 'date_from',
                       type: 'date_time',
                       control_type: 'date_time',
                       convert_output: 'render_iso8601_timestamp',
                       convert_input: 'render_epoch_time' },
                     { name: 'date_to',
                       type: 'date_time',
                       control_type: 'date_time',
                       convert_output: 'render_iso8601_timestamp',
                       convert_input: 'render_epoch_time' }
                   ] },
                 { name: 'payment_method', type: 'object',
                   properties: call('payment_method_schema', '').
                     ignored('gateway').
                     concat([
                              { name: 'tmp_token', label: 'Temporary token' }
                            ]) },
                 { name: 'charges', label: 'Charges', type: 'array', of: 'object',
                   properties: [
                     { name: 'amount',
                       type: 'integer',
                       control_type: 'number',
                       convert_output: 'integer_conversion',
                       convert_input: 'integer_conversion' },
                     { name: 'amount_in_decimal' },
                     { name: 'description' },
                     { name: 'taxable',
                       type: 'boolean',
                       control_type: 'checkbox',
                       convert_output: 'boolean_conversion',
                       toggle_hint: 'Select from list',
                       convert_input: 'boolean_conversion',
                       toggle_field: { name: 'taxable',
                                       label: 'Taxable',
                                       type: 'string',
                                       control_type: 'text',
                                       optional: true,
                                       sticky: true,
                                       convert_output: 'boolean_conversion',
                                       convert_input: 'boolean_conversion',
                                       hint: 'Accepted values are true or false',
                                       toggle_hint: 'Use custom value' } },
                     { name: 'tax_profile_id' },
                     { name: 'avalara_tax_code' },
                     { name: 'taxjar_product_code' },
                     { name: 'avalara_sale_type', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'avalara_sale_type',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'avalara_sale_type',
                         label: 'Avalara sale type',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'wholesale', 'retail', 'consumed', 'vendor_use'"
                       } },
                     { name: 'avalara_transaction_type',
                       type: 'integer',
                       control_type: 'integer',
                       convert_output: 'integer_conversion',
                       convert_input: 'integer_conversion' },
                     { name: 'avalara_service_type',
                       type: 'integer',
                       control_type: 'integer',
                       convert_output: 'integer_conversion',
                       convert_input: 'integer_conversion' },
                     { name: 'date_from',
                       type: 'date_time',
                       control_type: 'date_time',
                       convert_output: 'render_iso8601_timestamp',
                       convert_input: 'render_epoch_time' },
                     { name: 'date_to',
                       type: 'date_time',
                       control_type: 'date_time',
                       convert_output: 'render_iso8601_timestamp',
                       convert_input: 'render_epoch_time' }
                   ] },
                 { name: 'notes_to_remove', type: 'array', of: 'object',
                   properties: [
                     { name: 'entity_type', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'entity_type',
                       extends_schema: true,
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'entity_type',
                         label: 'Entity type',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         extends_schema: true,
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'plan', 'addon', 'customer', 'subscription', 'coupon'"
                       } }
                   ] }
               ])
    end,
    credit_note_create_input: lambda do |_input|
      call('credit_note_schema').only('reference_invoice_id', 'total', 'type',
                                      'reason_code', 'create_reason_code', 'date', 'customer_notes',
                                      'comment').
        concat(
          [
            { name: 'line_items', type: 'array', of: 'object',
              properties: call('line_items_schema').
                            ignored('customer_id', 'is_taxed',
                                    'item_level_discount_amount', 'object',
                                    'pricing_model', 'amount_in_decimal',
                                    'tax_rate', 'tax_amount',
                                    'tax_exempt_reason', 'entity_id') }
          ]
        )
    end,
    quote_for_update_subscription_item_create_input: lambda do |_input|
      [
        { name: 'name', sticky: true,
          hint: 'The quote name will be used as the pdf name of the quote.' },
        { name: 'notes', sticky: true,
          hint: 'Notes specific to this quote that you want customers ' \
                'to see on the quote PDF.' },
        { name: 'expires_at', sticky: true,
          type: 'date_time', control_type: 'date_time',
          convert_input: 'render_epoch_time',
          convert_output: 'render_iso8601_timestamp',
          hint: 'Quotes will be vaild till this date. After this ' \
                'quote will be marked as closed.' },
        { name: 'mandatory_items_to_remove', sticky: true,
          type: 'array', of: 'string',
          hint: 'Item IDs of mandatorily attached addons that are to be ' \
                'removed from the subscription.' },
        { name: 'replace_items_list', type: 'boolean',
          control_type: 'checkbox',
          optional: true, sticky: true,
          convert_input: 'boolean_conversion',
          toggle_hint: 'Select from list',
          hint: 'If true then the existing subscription_items list ' \
                'for the subscription is replaced by the one provided. ' \
                'If false then the provided subscription_items list gets ' \
                'added to the existing list.',
          toggle_field: {
            name: 'replace_items_list', label: 'Replace items list',
            type: 'string', control_type: 'text',
            optional: true, sticky: true,
            convert_input: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are true or false.'
          } },
        { name: 'billing_cycles', sticky: true,
          type: 'integer', control_type: 'integer',
          convert_input: 'integer_conversion',
          hint: 'Billing cycles set for plan-item price is used by default.' },
        { name: 'terms_to_charge', sticky: true,
          type: 'integer', control_type: 'integer',
          convert_input: 'integer_conversion',
          hint: 'The number of subscription billing cycles to invoice in ' \
                'advance. If a new term is started for the subscription ' \
                'due to this API call, then terms_to_charge is inclusive ' \
                'of this new term. See description for the force_term_reset ' \
                'parameter to learn more about when a subscription ' \
                'term is reset.' },
        { name: 'reactivate_from', type: 'date_time',
          control_type: 'date_time',
          convert_input: 'render_epoch_time',
          convert_output: 'render_iso8601_timestamp',
          hint: 'If the subscription status is cancelled and it is being ' \
                'reactivated via this operation, this is the date/time at ' \
                'which the subscription should be reactivated. Refer '\
                "<a href='https://apidocs.chargebee.com/docs/api/quotes#" \
                "create_a_quote_for_update_subscription_items' target= " \
                "'_blank'>API documentation</a> for more information." },
        { name: 'billing_alignment_mode', type: 'string', sticky: true,
          control_type: 'select', pick_list: 'billing_alignment_mode',
          hint: 'Override the billing alignment mode for Calendar Billing. ' \
                'Only applicable when using Calendar Billing. ',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'billing_alignment_mode', label: 'Billing alignment mode',
            optional: true, sticky: true,
            type: 'string', control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: 'Override the billing alignment mode for Calendar Billing. ' \
                  'Only applicable when using Calendar Billing. ' \
                  "Allowed values are 'immediate', 'delayed'"
          } },
        { name: 'coupon_ids', label: 'Coupon IDs',
          type: 'array', of: 'string',
          hint: 'Identifier of the coupon as a List. Coupon Codes ' \
                'can also be passed.' },
        { name: 'replace_coupon_list',
          type: 'boolean', control_type: 'checkbox',
          convert_input: 'boolean_conversion',
          toggle_hint: 'Select from list',
          sticky: true,
          toggle_field: {
            name: 'replace_coupon_list', label: 'Replace coupon list',
            optional: true, sticky: true,
            type: 'string', control_type: 'text',
            convert_input: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: true, false.'
          } },
        { name: 'change_option', control_type: 'select',
          optional: true, sticky: true,
          pick_list: %w[immediately specific_date].map { |e| [e.labelize, e] },
          toggle_hint: 'Select from list',
          hint: 'When the quote is converted, this attribute determines ' \
                'the date/time as of when the subscription change ' \
                'is to be carried out.',
          toggle_field: {
            name: 'change_option', label: 'Change option',
            type: 'string', control_type: 'text',
            optional: true, sticky: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are <b>immediately, specific_date</b>.'
          } },
        { name: 'changes_scheduled_at', type: 'date_time',
          control_type: 'date_time',
          convert_input: 'render_epoch_time',
          convert_output: 'render_iso8601_timestamp',
          hint: 'When change_option is set to specific_date, then set the ' \
                'date/time at which the subscription change is to happen or ' \
                'has happened. changes_scheduled_at can be set to a value in ' \
                'the past. This is called backdating the subscription change ' \
                'and is performed when the subscription change has already ' \
                'been provisioned but its billing has been delayed. Refer '\
                "<a href='https://apidocs.chargebee.com/docs/api/quotes#" \
                "create_a_quote_for_update_subscription_items' target= " \
                "'_blank'>API documentation</a> for more information." },
        { name: 'force_term_reset', type: 'boolean',
          control_type: 'checkbox',
          toggle_hint: 'Select from list',
          convert_input: 'boolean_conversion',
          toggle_field: {
            name: 'force_term_reset', label: 'Force term reset',
            type: 'string', control_type: 'text',
            optional: true, sticky: true,
            convert_input: 'boolean_conversion',
            hint: 'Accepted values are true or false',
            toggle_hint: 'Use custom value'
          } },
        { name: 'reactivate', type: 'boolean',
          control_type: 'checkbox',
          toggle_hint: 'Select from list',
          convert_input: 'boolean_conversion',
          toggle_field: {
            name: 'reactivate', label: 'Reactivate',
            type: 'string', control_type: 'text',
            optional: true, sticky: true,
            convert_input: 'boolean_conversion',
            hint: 'Accepted values are true or false',
            toggle_hint: 'Use custom value'
          } },
        { name: 'subscription', type: 'object',
          properties: call('subscription_schema', '').
            only('id', 'start_date', 'trial_end', 'auto_collection',
                 'offline_payment_method',
                 'contract_term_billing_cycle_on_renewal') },
        { name: 'billing_address', type: 'object',
          properties: call('business_address_schema', '') },
        { name: 'shipping_address', type: 'object',
          properties: call('business_address_schema', '') },
        { name: 'customer', type: 'object',
          properties: call('customer_schema', '').
            only('vat_number', 'vat_number_prefix', 'registered_for_gst') },
        { name: 'contract_term', type: 'object',
          properties: [
            { name: 'action_at_term_end', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'quote_action_at_term_end',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'action_at_term_end',
                label: 'Action at term end',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'renew', 'cancel', 'renew_once'"
              } },
            { name: 'cancellation_cutoff_period', type: 'integer', control_type: 'integer',
              convert_input: 'integer_conversion',
              hint: 'The number of days before contract_end, during which the ' \
                    'customer is barred from canceling the contract term. ' \
                    'The customer is allowed to cancel the contract term via ' \
                    'the Self-Serve Portal only before this period. This ' \
                    'allows you to have sufficient time for processing ' \
                    'the contract term closure.' }
          ] },
        { name: 'subscription_items',
          type: 'array', of: 'object',
          properties: [
            { name: 'item_price_id' },
            { name: 'quantity', type: 'integer', control_type: 'integer',
              convert_output: 'integer_conversion',
              convert_input: 'integer_conversion' },
            { name: 'quantity_in_decimal' },
            { name: 'unit_price', type: 'integer', control_type: 'number',
              convert_output: 'integer_conversion',
              convert_input: 'integer_conversion' },
            { name: 'unit_price_in_decimal' },
            { name: 'billing_cycles', type: 'integer', control_type: 'integer',
              convert_output: 'integer_conversion',
              convert_input: 'integer_conversion' },
            { name: 'trial_end', type: 'date_time', control_type: 'date_time',
              convert_output: 'render_iso8601_timestamp',
              convert_input: 'render_epoch_time' },
            { name: 'service_period_days',
              type: 'integer',
              control_type: 'integer',
              convert_output: 'integer_conversion',
              convert_input: 'integer_conversion' },
            { name: 'charge_on_event', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'on_event',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'charge_on_event',
                label: 'Charge on event',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'subscription_creation', 'subscription_trial_start', " \
                      "'plan_activation', 'subscription_activation', 'contract_termination'"
              } },
            { name: 'charge_once',
              type: 'boolean',
              control_type: 'checkbox',
              convert_output: 'boolean_conversion',
              toggle_hint: 'Select from list',
              convert_input: 'boolean_conversion',
              toggle_field: {
                name: 'charge_once', label: 'Charge once',
                type: 'string', control_type: 'text',
                optional: true, sticky: true,
                convert_output: 'boolean_conversion',
                convert_input: 'boolean_conversion',
                hint: 'Accepted values are true or false',
                toggle_hint: 'Use custom value'
              } },
            { name: 'charge_on_option', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'charge_on',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'charge_on_option',
                label: 'Charge on option',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'immediately', 'on_event'"
              } }
          ] },
        { name: 'discounts', type: 'array', of: 'object', sticky: true,
          properties: call('discount_schema') },
        { name: 'item_tiers', type: 'array', of: 'object',
          properties: [
            { name: 'item_price_id' },
            { name: 'starting_unit',
              type: 'integer',
              control_type: 'integer',
              convert_output: 'integer_conversion',
              convert_input: 'integer_conversion' },
            { name: 'ending_unit',
              type: 'integer',
              control_type: 'integer',
              convert_output: 'integer_conversion',
              convert_input: 'integer_conversion' },
            { name: 'price',
              type: 'integer',
              control_type: 'number',
              convert_output: 'integer_conversion',
              convert_input: 'integer_conversion' },
            { name: 'starting_unit_in_decimal' },
            { name: 'ending_unit_in_decimal' },
            { name: 'price_in_decimal' }
          ] }
      ]
    end,
    quote_for_update_subscription_item_update_input: lambda do |_input|
      [
        { name: 'quote_id', optional: false }
      ].concat(call('quote_for_update_subscription_item_create_input', '').
        ignored('name'))
    end,
    quote_for_update_subscription_item_create_output: lambda do |_input|
      [
        { name: 'quote', type: 'object',
          properties: call('quote_schema') },
        { name: 'quoted_subscription', type: 'object',
          properties: call('quoted_subscription_schema') }
      ]
    end,
    quote_for_update_subscription_item_update_output: lambda do |_input|
      call('quote_for_update_subscription_item_create_output', '')
    end,
    credit_note_create_output: lambda do |_input|
      call('credit_note_schema').
        concat([
                 { name: 'invoice', type: 'object',
                   properties: call('invoice_schema', '') }
               ])
    end,
    comment_create_output: lambda do |_input|
      [
        { name: 'id' },
        { name: 'added_by' },
        { name: 'created_at',
          type: 'date_time', control_type: 'date_time',
          convert_output: 'epoch_to_iso' },
        { name: 'entity_id' },
        { name: 'entity_type' },
        { name: 'notes' },
        { name: 'object' },
        { name: 'type' }
      ]
    end,
    invoice_create_output: lambda do |_input|
      call('invoice_schema', '')
    end,
    invoice_charge_create_output: lambda do |_input|
      call('invoice_schema', '')
    end,
    hierarchy_access_setting_update_input: lambda do |_input|
      [
        { name: 'customer_id', optional: false },
        { name: 'use_default_hierarchy_settings',
          type: 'boolean',
          control_type: 'checkbox',
          convert_output: 'boolean_conversion',
          toggle_hint: 'Select from list',
          convert_input: 'boolean_conversion',
          toggle_field: {
            name: 'use_default_hierarchy_settings',
            label: 'Use default hierarchy settings',
            type: 'string',
            control_type: 'text',
            optional: true,
            sticky: true,
            convert_output: 'boolean_conversion',
            convert_input: 'boolean_conversion',
            hint: 'Accepted values are true or false',
            toggle_hint: 'Use custom value'
          } },
        { name: 'parent_account_access', type: 'object',
          properties: call('parent_account_access_schema', '') },
        { name: 'child_account_access', type: 'object',
          properties: call('child_account_access_schema', '') }
      ]
    end,
    hierarchy_access_setting_update_output: lambda do |input|
      call('customer_schema', input)
    end,
    subscription_for_customer_create_input: lambda do |input|
      call('subscription_schema', input).required('customer_id', 'plan_id').
        only('customer_id', 'id', 'plan_id', 'plan_quantity', 'plan_quantity_in_decimal', 'plan_unit_price',
             'plan_unit_price_in_decimal', 'setup_fee', 'trial_end', 'billing_cycles',
             'mandatory_addons_to_remove', 'start_date', 'auto_collection', 'terms_to_charge',
             'billing_alignment_mode', 'offline_payment_method', 'po_number', 'coupon_ids',
             'payment_source_id', 'override_relationship', 'invoice_notes', 'meta_data',
             'invoice_immediately', 'free_period', 'free_period_unit',
             'contract_term_billing_cycle_on_renewal', 'shipping_address', 'payment_intent',
             'addons', 'event_based_addons', 'trial_end_action').
        concat([
                 { name: 'replace_primary_payment_source',
                   type: 'boolean',
                   control_type: 'checkbox',
                   convert_output: 'boolean_conversion',
                   toggle_hint: 'Select from list',
                   convert_input: 'boolean_conversion',
                   toggle_field: { name: 'replace_primary_payment_source',
                                   label: 'Replace primary payment source',
                                   type: 'string',
                                   control_type: 'text',
                                   optional: true,
                                   sticky: true,
                                   convert_output: 'boolean_conversion',
                                   convert_input: 'boolean_conversion',
                                   hint: 'Accepted values are true or false',
                                   toggle_hint: 'Use custom value' } },
                 { name: 'contract_term', type: 'object',
                   properties: [
                     { name: 'action_at_term_end', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'action_at_term_end',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'action_at_term_end',
                         label: 'Action at term end',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'renew', 'cancel'"
                       } },
                     { name: 'cancellation_cutoff_period', type: 'integer', control_type: 'integer',
                       convert_input: 'integer_conversion',
                       hint: 'The number of days before contract_end, during which the ' \
                             'customer is barred from canceling the contract term. ' \
                             'The customer is allowed to cancel the contract term via ' \
                             'the Self-Serve Portal only before this period. This ' \
                             'allows you to have sufficient time for processing ' \
                             'the contract term closure.' }
                   ] },
                 { name: 'schema_builder',
                   extends_schema: true,
                   control_type: 'schema-designer',
                   label: 'Data fields',
                   sticky: true,
                   empty_schema_title: 'Describe all fields for your meta fields.',
                   hint: 'A set of key-value pairs stored as additional information for ' \
                         'the subscription. Describe all your metadata fields.',
                   optional: true,
                   sample_data_type: 'json' }
               ])
    end,
    subscription_update_input: lambda do |input|
      call('subscription_schema', input).
        only('id', 'plan_id', 'plan_quantity', 'plan_quantity_in_decimal', 'plan_unit_price',
             'plan_unit_price_in_decimal', 'setup_fee', 'trial_end', 'billing_cycles',
             'mandatory_addons_to_remove', 'start_date', 'auto_collection', 'terms_to_charge',
             'billing_alignment_mode', 'offline_payment_method', 'po_number', 'coupon_ids',
             'payment_source_id', 'override_relationship', 'invoice_notes', 'meta_data',
             'invoice_immediately', 'free_period', 'free_period_unit',
             'contract_term_billing_cycle_on_renewal', 'shipping_address', 'payment_intent',
             'event_based_addons', 'trial_end_action', 'changes_scheduled_at').
        concat([
                 { name: 'replace_addon_list',
                   type: 'boolean',
                   control_type: 'checkbox',
                   convert_output: 'boolean_conversion',
                   toggle_hint: 'Select from list',
                   convert_input: 'boolean_conversion',
                   toggle_field: { name: 'replace_addon_list',
                                   label: 'Replace addon list',
                                   type: 'string',
                                   control_type: 'text',
                                   optional: true,
                                   sticky: true,
                                   convert_output: 'boolean_conversion',
                                   convert_input: 'boolean_conversion',
                                   hint: 'Accepted values are true or false',
                                   toggle_hint: 'Use custom value' } },
                 { name: 'invoice_date', type: 'date_time', control_type: 'date_time',
                   convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
                 { name: 'reactivate_from', type: 'date_time',
                   control_type: 'date_time',
                   convert_input: 'render_epoch_time',
                   convert_output: 'render_iso8601_timestamp',
                   hint: "Refer <a href='https://apidocs.chargebee.com/docs/api/" \
                         'subscriptions?prod_cat_ver=2#update_subscription_' \
                         "for_items' target='_blank'>API documentation</a> for " \
                         'more information' },
                 { name: 'change_option', control_type: 'select',
                   optional: true, sticky: true,
                   pick_list: %w[immediately end_of_term
                                 specific_date].map { |e| [e.labelize, e] },
                   toggle_hint: 'Select from list',
                   hint: 'When the quote is converted, this attribute determines ' \
                         'the date/time as of when the subscription change ' \
                         'is to be carried out.',
                   toggle_field: {
                     name: 'change_option', label: 'Change option',
                     type: 'string', control_type: 'text',
                     optional: true, sticky: true,
                     toggle_hint: 'Use custom value',
                     hint: 'Allowed values are <b>immediately, end_of_term, ' \
                           'specific_date</b>.'
                   } },
                 { name: 'replace_coupon_list',
                   type: 'boolean',
                   control_type: 'checkbox',
                   convert_output: 'boolean_conversion',
                   toggle_hint: 'Select from list',
                   convert_input: 'boolean_conversion',
                   toggle_field: { name: 'replace_coupon_list',
                                   label: 'Replace coupon list',
                                   type: 'string',
                                   control_type: 'text',
                                   optional: true,
                                   sticky: true,
                                   convert_output: 'boolean_conversion',
                                   convert_input: 'boolean_conversion',
                                   hint: 'Accepted values are true or false',
                                   toggle_hint: 'Use custom value' } },
                 { name: 'prorate',
                   type: 'boolean',
                   control_type: 'checkbox',
                   convert_output: 'boolean_conversion',
                   toggle_hint: 'Select from list',
                   convert_input: 'boolean_conversion',
                   toggle_field: { name: 'prorate',
                                   label: 'Prorate',
                                   type: 'string',
                                   control_type: 'text',
                                   optional: true,
                                   sticky: true,
                                   convert_output: 'boolean_conversion',
                                   convert_input: 'boolean_conversion',
                                   hint: 'Accepted values are true or false',
                                   toggle_hint: 'Use custom value' } },
                 { name: 'end_of_term',
                   type: 'boolean',
                   control_type: 'checkbox',
                   convert_output: 'boolean_conversion',
                   toggle_hint: 'Select from list',
                   convert_input: 'boolean_conversion',
                   toggle_field: { name: 'end_of_term',
                                   label: 'End of term',
                                   type: 'string',
                                   control_type: 'text',
                                   optional: true,
                                   sticky: true,
                                   convert_output: 'boolean_conversion',
                                   convert_input: 'boolean_conversion',
                                   hint: 'Accepted values are true or false',
                                   toggle_hint: 'Use custom value' } },
                 { name: 'force_term_reset',
                   type: 'boolean',
                   control_type: 'checkbox',
                   convert_output: 'boolean_conversion',
                   toggle_hint: 'Select from list',
                   convert_input: 'boolean_conversion',
                   toggle_field: { name: 'force_term_reset',
                                   label: 'Force term reset',
                                   type: 'string',
                                   control_type: 'text',
                                   optional: true,
                                   sticky: true,
                                   convert_output: 'boolean_conversion',
                                   convert_input: 'boolean_conversion',
                                   hint: 'Accepted values are true or false',
                                   toggle_hint: 'Use custom value' } },
                 { name: 'reactivate',
                   type: 'boolean',
                   control_type: 'checkbox',
                   convert_output: 'boolean_conversion',
                   toggle_hint: 'Select from list',
                   convert_input: 'boolean_conversion',
                   toggle_field: { name: 'reactivate',
                                   label: 'Reactivate',
                                   type: 'string',
                                   control_type: 'text',
                                   optional: true,
                                   sticky: true,
                                   convert_output: 'boolean_conversion',
                                   convert_input: 'boolean_conversion',
                                   hint: 'Accepted values are true or false',
                                   toggle_hint: 'Use custom value' } },
                 { name: 'token_id' },
                 { name: 'contract_term', type: 'object',
                   properties: [
                     { name: 'action_at_term_end', type: 'string', sticky: true,
                       control_type: 'select',
                       pick_list: %w[renew cancel renew_once].
                                    map { |e| [e.labelize, e] },
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'action_at_term_end',
                         label: 'Action at term end',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'renew', 'cancel' and 'renew_once'."
                       } },
                     { name: 'cancellation_cutoff_period', type: 'integer', control_type: 'integer',
                       convert_input: 'integer_conversion',
                       hint: 'The number of days before contract_end, during which the ' \
                             'customer is barred from canceling the contract term. ' \
                             'The customer is allowed to cancel the contract term via ' \
                             'the Self-Serve Portal only before this period. This ' \
                             'allows you to have sufficient time for processing ' \
                             'the contract term closure.' }
                   ] },
                 { name: 'card', type: 'object',
                   properties: call('card_schema').
                    only('gateway_account_id', 'first_name', 'last_name', 'number',
                         'expiry_month', 'expiry_year', 'cvv', 'billing_addr1', 'billing_addr2',
                         'billing_city', 'billing_state_code', 'billing_state', 'billing_zip',
                         'billing_country', 'additional_information').
                    concat([
                      { name: 'number', optional: false,
                        hint: 'The credit card number without any format. ' \
                              'If you are using Braintree.js, you can ' \
                              'specify the Braintree encrypted card number here.' }
                      ])},
                 { name: 'addons', type: 'array', of: 'object',
                   properties: [
                     { name: 'id' },
                     { name: 'quantity', type: 'integer', control_type: 'integer',
                       convert_output: 'integer_conversion' },
                     { name: 'unit_price', type: 'number', control_type: 'number' },
                     { name: 'amount', type: 'number', control_type: 'number' },
                     { name: 'trial_end', type: 'date_time', control_type: 'date_time',
                       convert_input: 'render_epoch_time', convert_output: 'render_iso8601_timestamp' },
                     { name: 'billing_cycles', type: 'integer',
                       control_type: 'integer',
                       convert_output: 'integer_conversion' },
                     { name: 'quantity_in_decimal' },
                     { name: 'unit_price_in_decimal' }
                   ] },
                 { name: 'payment_method', type: 'object',
                   properties: call('payment_method_schema', '').ignored('gateway') },
                 { name: 'billing_address', type: 'object', properties:
                   call('business_address_schema', '') },
                 { name: 'customer', type: 'object',
                   properties: call('customer_schema', '').
                     only('vat_number', 'vat_number_prefix', 'registered_for_gst',
                          'business_customer_without_vat_number',
                          'entity_identifier_scheme', 'is_einvoice_enabled',
                          'entity_identifier_standard') },
                 { name: 'schema_builder',
                   extends_schema: true,
                   control_type: 'schema-designer',
                   label: 'Data fields',
                   sticky: true,
                   empty_schema_title: 'Describe all fields for your meta fields.',
                   hint: 'A set of key-value pairs stored as additional information for ' \
                         'the subscription. Describe all your metadata fields.',
                   optional: true,
                   sample_data_type: 'json' }
               ])
    end,
    subscription_update_output: lambda do |input|
      call('subscription_schema', input).
        concat([
                 { name: 'customer', type: 'object',
                   properties: call('customer_schema', input) },
                 { name: 'card', type: 'object',
                   properties: call('card_schema') },
                 { name: 'invoice', type: 'object',
                   properties: call('invoice_schema', input) },
                 { name: 'unbilled_charge', type: 'object',
                   properties: call('unbilled_charge_schema', input) },
                 { name: 'credit_note', label: 'Credit notes',
                   type: 'object',
                   properties: call('credit_note_schema') }
               ])
    end,
    subscription_for_item_create_input: lambda do |input|
      call('subscription_schema', input).required('customer_id').
        only('customer_id', 'id', 'plan_id', 'plan_quantity', 'plan_quantity_in_decimal', 'plan_unit_price',
             'plan_unit_price_in_decimal', 'setup_fee', 'trial_end', 'billing_cycles',
             'mandatory_addons_to_remove', 'start_date', 'auto_collection', 'terms_to_charge',
             'billing_alignment_mode', 'offline_payment_method', 'po_number', 'coupon_ids',
             'payment_source_id', 'override_relationship', 'invoice_notes', 'meta_data',
             'invoice_immediately', 'free_period', 'free_period_unit', 'item_tiers',
             'contract_term_billing_cycle_on_renewal', 'shipping_address', 'payment_intent',
             'addons', 'event_based_addons', 'create_pending_invoices', 'auto_close_invoices',
             'trial_end_action').
        concat([
                 { name: 'mandatory_items_to_remove', type: 'array', of: 'string',
                   hint: 'Item IDs of mandatorily attached addons that are to ' \
                         'be removed from the subscription.' },
                 { name: 'invoice_date', type: 'date_time',
                   control_type: 'date_time',
                   convert_input: 'render_epoch_time',
                   convert_output: 'render_iso8601_timestamp',
                   hint: "Refer <a href='https://apidocs.chargebee.com/docs/api/" \
                         'subscriptions?prod_cat_ver=2#update_subscription_' \
                         "for_items' target='_blank'>API documentation</a> for " \
                         'more information' },
                 { name: 'replace_primary_payment_source',
                   type: 'boolean',
                   control_type: 'checkbox',
                   convert_output: 'boolean_conversion',
                   toggle_hint: 'Select from list',
                   convert_input: 'boolean_conversion',
                   toggle_field: { name: 'replace_primary_payment_source',
                                   label: 'Replace primary payment source',
                                   type: 'string',
                                   control_type: 'text',
                                   optional: true,
                                   sticky: true,
                                   convert_output: 'boolean_conversion',
                                   convert_input: 'boolean_conversion',
                                   hint: 'Accepted values are true or false',
                                   toggle_hint: 'Use custom value' } },
                 { name: 'first_invoice_pending',
                   type: 'boolean', control_type: 'checkbox',
                   convert_input: 'boolean_conversion',
                   toggle_hint: 'Select from list',
                   sticky: true,
                   toggle_field: {
                     name: 'first_invoice_pending', label: 'First invoice pending',
                     optional: true, sticky: true,
                     type: 'string', control_type: 'text',
                     convert_input: 'boolean_conversion',
                     toggle_hint: 'Use custom value',
                     hint: 'Allowed values are: true, false.'
                   } },
                 { name: 'contract_term', type: 'object',
                   properties: [
                     { name: 'action_at_term_end', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'action_at_term_end',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'action_at_term_end',
                         label: 'Action at term end',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'renew', 'cancel'"
                       } },
                     { name: 'cancellation_cutoff_period', type: 'integer', control_type: 'integer',
                       convert_input: 'integer_conversion',
                       hint: 'The number of days before contract_end, during which the ' \
                             'customer is barred from canceling the contract term. ' \
                             'The customer is allowed to cancel the contract term via ' \
                             'the Self-Serve Portal only before this period. This ' \
                             'allows you to have sufficient time for processing ' \
                             'the contract term closure.' }
                   ] },
                 { name: 'subscription_items',
                   type: 'array', of: 'object',
                   properties: [
                     { name: 'item_price_id' },
                     { name: 'quantity', type: 'integer', control_type: 'integer',
                       convert_output: 'integer_conversion',
                       convert_input: 'integer_conversion' },
                     { name: 'quantity_in_decimal' },
                     { name: 'free_quantity_in_decimal' },
                     { name: 'amount_in_decimal' },
                     { name: 'amount', type: 'number', control_type: 'number' },
                     { name: 'unit_price', type: 'integer', control_type: 'number',
                       convert_output: 'integer_conversion',
                       convert_input: 'integer_conversion' },
                     { name: 'unit_price_in_decimal' },
                     { name: 'billing_cycles', type: 'integer', control_type: 'integer',
                       convert_output: 'integer_conversion',
                       convert_input: 'integer_conversion' },
                     { name: 'trial_end', type: 'date_time', control_type: 'date_time',
                       convert_output: 'render_iso8601_timestamp',
                       convert_input: 'render_epoch_time' },
                     { name: 'service_period_days',
                       type: 'integer',
                       control_type: 'integer',
                       convert_output: 'integer_conversion',
                       convert_input: 'integer_conversion' },
                     { name: 'charge_on_event', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'on_event',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'charge_on_event',
                         label: 'Charge on event',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'subscription_creation', 'subscription_trial_start', " \
                               "'plan_activation', 'subscription_activation', 'contract_termination'"
                       } },
                     { name: 'charge_once',
                       type: 'boolean',
                       control_type: 'checkbox',
                       convert_output: 'boolean_conversion',
                       toggle_hint: 'Select from list',
                       convert_input: 'boolean_conversion',
                       toggle_field: { name: 'charge_once',
                                       label: 'Charge once',
                                       type: 'string',
                                       control_type: 'text',
                                       optional: true,
                                       sticky: true,
                                       convert_output: 'boolean_conversion',
                                       convert_input: 'boolean_conversion',
                                       hint: 'Accepted values are true or false',
                                       toggle_hint: 'Use custom value' } },
                     { name: 'charge_on_option', type: 'string', sticky: true,
                       control_type: 'select', pick_list: 'charge_on',
                       toggle_hint: 'Select from list',
                       toggle_field: {
                         name: 'charge_on_option',
                         label: 'Charge on option',
                         optional: true,
                         sticky: true,
                         type: 'string',
                         control_type: 'text',
                         toggle_hint: 'Use custom value',
                         hint: "Allowed values are 'immediately', 'on_event'"
                       } }
                   ] },
                 { name: 'discounts', type: 'array', of: 'object', sticky: true,
                   properties: call('discount_schema') },
                 { name: 'schema_builder',
                   extends_schema: true,
                   control_type: 'schema-designer',
                   label: 'Data fields',
                   sticky: true,
                   empty_schema_title: 'Describe all fields for your meta fields.',
                   hint: 'A set of key-value pairs stored as additional information for ' \
                         'the subscription. Describe all your metadata fields.',
                   optional: true,
                   sample_data_type: 'json' }
               ])
    end,
    discount_schema: lambda do
      [
        { name: 'apply_on', control_type: 'select',
          optional: false, sticky: true,
          pick_list: %w[invoice_amount specific_item_price].
            map { |e| [e.labelize, e] },
          hint: 'The amount on the invoice to which the discount is applied.',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'apply_on', label: 'Apply on',
            optional: false, sticky: true,
            type: 'string', control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are <b>invoice_amount, specific_item_price</b>.'
          } },
        { name: 'duration_type', type: 'string',
          sticky: true, optional: false,
          control_type: 'select', pick_list: 'duration_type',
          hint: 'Specifies the time duration for which this discount ' \
                'is attached to the subscription.',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'duration_type', label: 'Duration type',
            optional: false, sticky: true,
            type: 'string', control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: "Allowed values are 'one_time', 'forever', 'limited_period'"
          } },
        { name: 'percentage', type: 'number', control_type: 'number',
          convert_input: 'float_conversion',
          sticky: true },
        { name: 'amount', type: 'integer', control_type: 'integer',
          convert_input: 'integer_conversion',
          sticky: true },
        { name: 'period', type: 'integer', control_type: 'integer',
          convert_input: 'integer_conversion',
          sticky: true },
        { name: 'period_unit', type: 'string', sticky: true,
          control_type: 'select', pick_list: 'period_unit',
          toggle_hint: 'Select from list',
          hint: 'The unit of time for period. Applicable only when ' \
                'duration_type is limited_period.',
          toggle_field: {
            name: 'period_unit', label: 'Period unit',
            optional: true, sticky: true,
            type: 'string', control_type: 'text',
            toggle_hint: 'Use custom value',
            hint: "Allowed values are 'day', 'week', 'month', 'year'"
          } },
        { name: 'included_in_mrr', label: 'Included in MRR',
          type: 'boolean', control_type: 'checkbox',
          convert_input: 'boolean_conversion',
          toggle_hint: 'Select from list',
          sticky: true,
          toggle_field: {
            name: 'included_in_mrr', label: 'Included in MRR',
            optional: true, sticky: true,
            type: 'string', control_type: 'text',
            convert_input: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: true, false.'
          } },
        { name: 'item_price_id',
          hint: 'The id of the item price in the subscription to which ' \
                'the discount is to be applied. Relevant only when ' \
                'apply_on = specific_item_price.' },
        { name: 'id',
          hint: 'The id of the discount to be removed. This parameter ' \
                'is only relevant when discounts[operation_type] is remove.' },
        { name: 'operation_type', control_type: 'select',
          optional: false, sticky: true,
          pick_list: %w[add remove].map { |e| [e.labelize, e] },
          hint: 'The operation to be carried out for the discount.',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'operation_type', label: 'Operation type',
            optional: false, sticky: true,
            type: 'string', control_type: 'text',
            toggle_hint: 'Use custom valuee',
            hint: 'Allowed values are <b>add, remove</b>'
          } }
      ]
    end,
    subscription_for_item_update_input: lambda do |input|
      [
        { name: 'subscription_id', optional: false },
        { name: 'mandatory_items_to_remove', type: 'array', of: 'string',
          sticky: true,
          hint: 'Item IDs of mandatorily attached addons that are to ' \
                'be removed from the subscription.' },
        { name: 'replace_items_list',
          type: 'boolean', control_type: 'checkbox',
          convert_input: 'boolean_conversion',
          toggle_hint: 'Select from list',
          sticky: true,
          hint: 'If true then the existing subscription_items list for ' \
                'the subscription is replaced by the one provided. If ' \
                'false then the provided subscription_items list ' \
                'gets added to the existing list.',
          toggle_field: {
            name: 'replace_items_list', label: 'Replace items list',
            optional: true, sticky: true,
            type: 'string', control_type: 'text',
            convert_input: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: true, false.'
          } },
        { name: 'invoice_date', type: 'date_time',
          control_type: 'date_time',
          convert_input: 'render_epoch_time',
          convert_output: 'render_iso8601_timestamp',
          hint: "Refer <a href='https://apidocs.chargebee.com/docs/api/" \
                'subscriptions?prod_cat_ver=2#update_subscription_' \
                "for_items' target='_blank'>API documentation</a> for " \
                'more information' },
        { name: 'reactivate_from', type: 'date_time',
          control_type: 'date_time',
          convert_input: 'render_epoch_time',
          convert_output: 'render_iso8601_timestamp',
          hint: "Refer <a href='https://apidocs.chargebee.com/docs/api/" \
                'subscriptions?prod_cat_ver=2#update_subscription_' \
                "for_items' target='_blank'>API documentation</a> for " \
                'more information' },
        { name: 'replace_coupon_list',
          type: 'boolean', control_type: 'checkbox',
          convert_input: 'boolean_conversion',
          toggle_hint: 'Select from list',
          sticky: true,
          toggle_field: {
            name: 'replace_coupon_list', label: 'Replace coupon list',
            optional: true, sticky: true,
            type: 'string', control_type: 'text',
            convert_input: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: true, false.'
          } },
        { name: 'prorate',
          type: 'boolean', control_type: 'checkbox',
          convert_input: 'boolean_conversion',
          toggle_hint: 'Select from list',
          sticky: true,
          toggle_field: {
            name: 'prorate', label: 'Prorate',
            optional: true, sticky: true,
            type: 'string', control_type: 'text',
            convert_input: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: true, false.'
          } },
        { name: 'end_of_term',
          type: 'boolean',
          control_type: 'checkbox',
          convert_output: 'boolean_conversion',
          toggle_hint: 'Select from list',
          convert_input: 'boolean_conversion',
          toggle_field: { name: 'end_of_term',
                          label: 'End of term',
                          type: 'string',
                          control_type: 'text',
                          optional: true,
                          sticky: true,
                          convert_output: 'boolean_conversion',
                          convert_input: 'boolean_conversion',
                          hint: 'Accepted values are true or false',
                          toggle_hint: 'Use custom value' } },
        { name: 'force_term_reset',
          type: 'boolean',
          control_type: 'checkbox',
          convert_output: 'boolean_conversion',
          toggle_hint: 'Select from list',
          convert_input: 'boolean_conversion',
          toggle_field: { name: 'force_term_reset',
                          label: 'Force term reset',
                          type: 'string',
                          control_type: 'text',
                          optional: true,
                          sticky: true,
                          convert_output: 'boolean_conversion',
                          convert_input: 'boolean_conversion',
                          hint: 'Accepted values are true or false',
                          toggle_hint: 'Use custom value' } },
        { name: 'reactivate',
          type: 'boolean',
          control_type: 'checkbox',
          convert_output: 'boolean_conversion',
          toggle_hint: 'Select from list',
          convert_input: 'boolean_conversion',
          toggle_field: { name: 'reactivate',
                          label: 'Reactivate',
                          type: 'string',
                          control_type: 'text',
                          optional: true,
                          sticky: true,
                          convert_output: 'boolean_conversion',
                          convert_input: 'boolean_conversion',
                          hint: 'Accepted values are true or false',
                          toggle_hint: 'Use custom value' } },
        { name: 'token_id' },
        { name: 'change_option', control_type: 'select',
          optional: true, sticky: true,
          pick_list: %w[immediately end_of_term
                        specific_date].map { |e| [e.labelize, e] },
          toggle_hint: 'Select from list',
          hint: 'When the quote is converted, this attribute determines ' \
                'the date/time as of when the subscription change ' \
                'is to be carried out.',
          toggle_field: {
            name: 'change_option', label: 'Change option',
            type: 'string', control_type: 'text',
            optional: true, sticky: true,
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are <b>immediately, end_of_term, ' \
                  'specific_date</b>.'
          } },
        { name: 'discounts', type: 'array', of: 'object', sticky: true,
          properties: call('discount_schema') }
      ].concat(
        call('subscription_schema', input).
          only('start_date', 'trial_end', 'billing_cycles', 'billing_alignment_mode',
               'auto_collection', 'offline_payment_method', 'po_number', 'coupon_ids',
               'invoice_immediately', 'override_relationship', 'changes_scheduled_at',
               'contract_term_billing_cycle_on_renewal', 'free_period', 'free_period_unit',
               'create_pending_invoices', 'auto_close_invoices', 'invoice_notes',
               'shipping_address', 'subscription_items', 'item_tiers', 'meta_data')
      ).concat(
        call('subscription_update_input', input).only('card', 'payment_method',
                                                      'payment_intent', 'billing_address', 'customer', 'contract_term',
                                                      'schema_builder')
      )
    end,
    invoice_detail_update_input: lambda do |_input|
      [
        { name: 'invoice_id', optional: false },
        { name: 'vat_number', label: 'VAT number', sticky: true,
          hint: 'VAT/ Tax registration number of the customer.' },
        { name: 'vat_number_prefix', label: 'VAT number prefix',
          sticky: true,
          hint: 'An overridden value for the first two characters of the ' \
                'full VAT number. Only applicable specifically for customers ' \
                'with billing_address country as XI (which is United ' \
                'Kingdom - Northern Ireland). Refer '\
                "<a href='https://apidocs.chargebee.com/docs/api/invoices?" \
                "prod_cat_ver=2#update_invoice_details' target='_blank'>" \
                'API documentation</a> for more information.' },
        { name: 'po_number', label: 'Purchase order number', sticky: true,
          hint: 'Purchase Order Number for this invoice.' },
        { name: 'comment', sticky: true,
          hint: 'An internal comment to be added for this operation, to ' \
                'the invoice. This comment is displayed on the Chargebee ' \
                'UI. It is not displayed on any customer-facing Hosted ' \
                'Page or any document such as the Invoice PDF.' },
        { name: 'shipping_address', type: 'object',
          properties: [
            { name: 'first_name' },
            { name: 'last_name' },
            { name: 'email' },
            { name: 'company' },
            { name: 'phone' },
            { name: 'line1', label: 'Address line 1' },
            { name: 'line2', label: 'Address line 2' },
            { name: 'line3', label: 'Address line 3' },
            { name: 'city' },
            { name: 'state_code',
              hint: 'The ISO 3166-2 state/province code without the country prefix. ' \
                    'Currently supported for USA, Canada and India. For instance, for ' \
                    'Arizona (USA), set state_code as AZ (not US-AZ). For Tamil Nadu ' \
                    '(India), set as TN (not IN-TN). For British Columbia (Canada), ' \
                    'set as BC (not CA-BC).' },
            { name: 'state',
              hint: 'The state/province name. Is set by Chargebee automatically for ' \
                    'US, Canada and India If state_code is provided.' },
            { name: 'country', hint: 'ISO 3166 alpha-2 country code.' },
            { name: 'zip' },
            { name: 'validation_status', control_type: 'select',
              pick_list: 'validation_status_list',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'validation_status', control_type: 'text',
                type: 'string',
                label: 'Customer type',
                optional: true,
                toggle_hint: 'Use custom value',
                hint: 'Allowed vaalues are: not_validated, valid, partially_valid, invalid'
              },
              hint: 'The address verification status.' }
          ] },
        { name: 'billing_address', type: 'object', properties:
          call('business_address_schema', '') }
      ]
    end,
    customer_create_output: lambda do |input|
      call('customer_schema', input).
        concat([
                 { name: 'card', type: 'object',
                   properties: call('card_schema') }
               ])
    end,
    subscription_for_customer_create_output: lambda do |input|
      call('subscription_schema', input).
        concat([
                 { name: 'customer', type: 'object',
                   properties: call('customer_schema', input) },
                 { name: 'card', type: 'object',
                   properties: call('card_schema') },
                 { name: 'invoice', type: 'object',
                   properties: call('invoice_schema', input) },
                 { name: 'unbilled_charge', type: 'object',
                   properties: call('unbilled_charge_schema', input) }
               ])
    end,
    subscription_for_item_create_output: lambda do |input|
      call('subscription_for_customer_create_output', input)
    end,
    customer_get_input: lambda do
      [
        { name: 'id', label: 'Customer ID', optional: false },
        {
          name: 'schema_builder',
          extends_schema: true,
          control_type: 'schema-designer',
          label: 'Data fields',
          sticky: true,
          empty_schema_title: 'Describe all fields for your meta fields.',
          hint: 'A set of key-value pairs stored as additional information for ' \
                'the customer. Describe all your metadata fields.',
          optional: true,
          sample_data_type: 'json' # json_input / xml
        }
      ]
    end,
    customer_get_output: lambda do |input|
      call('customer_schema', input).
        concat([
                 { name: 'card', type: 'object',
                   properties: call('card_schema') }
               ])
    end,
    plan_trigger_output: lambda do |input|
      call('plan_schema', input).
        concat([{ name: 'object' },
                { name: 'charge_model' }])
    end,
    addon_trigger_output: lambda do |input|
      call('addon_schema', input)
    end,
    customer_trigger_output: lambda do |input|
      call('customer_schema', input).
        concat([{ name: 'object' },
                { name: 'card_status' }])
    end,
    credit_note_trigger_output: lambda do |_input|
      call('credit_note_schema')
    end,
    customer_search_input: lambda do
      [
        { name: 'sort_by', type: 'object', sticky: true,
          properties: [
            { name: 'value', label: 'Attribute',
              type: 'string', sticky: true,
              control_type: 'select', pick_list: 'attribute_list',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Attribute',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'created_at', 'updated_at'"
              } },
            { name: 'sort_order', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'sort_order_list',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'sort_order',
                label: 'Sort order',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'asc', 'desc'"
              } }
          ] },
        { name: 'include_deleted', sticky: true,
          type: 'boolean', control_type: 'checkbox',
          convert_input: 'boolean_conversion',
          toggle_hint: 'Select from list',
          toggle_field: {
            name: 'include_deleted',
            label: 'Include deleted',
            optional: true, sticky: true,
            type: 'string', control_type: 'text',
            convert_input: 'boolean_conversion',
            toggle_hint: 'Use custom value',
            hint: 'Allowed values are: true, false.'
          } },
        { name: 'first_name', type: 'object',
          hint: 'First name of the customer.',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'string_filter_types',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'starts_with', 'is_present'"
              } },
            { name: 'value', sticky: true,
              hint: "If operator is 'is_present', allowed values are true/false" }
          ] },
        { name: 'last_name', type: 'object',
          hint: 'Last name of the customer.',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'string_filter_types',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'starts_with', 'is_present'"
              } },
            { name: 'value', sticky: true,
              hint: "If operator is 'is_present', allowed values are true/false" }
          ] },
        { name: 'email', type: 'object',
          hint: 'Email of the customer.',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'string_filter_types',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'starts_with', 'is_present'"
              } },
            { name: 'value', sticky: true, control_type: 'email',
              hint: "If operator is 'is_present', allowed values are true/false" }
          ] },
        { name: 'company', type: 'object',
          hint: 'Company name of the customer.',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'string_filter_types',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'starts_with', 'is_present'"
              } },
            { name: 'value', sticky: true,
              hint: "If operator is 'is_present', allowed values are true/false" }
          ] },
        { name: 'phone', type: 'object',
          hint: 'Phone number of the customer.',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'string_filter_types',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'starts_with', 'is_present'"
              } },
            { name: 'value', sticky: true,
              hint: "If operator is 'is_present', allowed values are true/false" }
          ] },
        { name: 'auto_collection', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'period_string_field_types',
              extends_schema: true,
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                extends_schema: true,
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'in', 'not_in'"
              } },
            { ngIf: 'input.auto_collection.operator == "in" || input.auto_collection.operator == "not_in"',
              name: 'value', type: 'string', sticky: true,
              control_type: 'multiselect', pick_list: 'auto_collection',
              delimiter: ',',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'on', 'off'. Multiple values can be " \
                      "seperated using comma(','). e.g. on,off"
              } },
            { ngIf: '!(input.auto_collection.operator == "in" || input.auto_collection.operator == "not_in")',
              name: 'value', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'auto_collection',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'on', 'off'"
              } }
          ] },
        { name: 'taxability', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'period_string_field_types',
              extends_schema: true,
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                extends_schema: true,
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'in', 'not_in'"
              } },
            { ngIf: 'input.taxability.operator == "in" || input.taxability.operator == "not_in"',
              name: 'value', type: 'string', sticky: true,
              control_type: 'multiselect', pick_list: 'tax_type',
              delimiter: ',',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'taxable', 'exempt'. Multiple values " \
                      "can be seperated using comma(','). e.g. taxable,exempt"
              } },
            { ngIf: '!(input.taxability.operator == "in" || input.taxability.operator == "not_in")',
              name: 'value', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'tax_type',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value',
                label: 'Value',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'taxable', 'exempt'"
              } }
          ] },
        { name: 'created_at', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'timestamp_filter_types',
              extends_schema: true,
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                extends_schema: true,
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'after', 'before', 'on', 'between'"
              } },
            { ngIf: 'input.created_at.operator == "between"',
              name: 'from', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time',
              convert_output: 'render_iso8601_timestamp', sticky: true },
            { ngIf: 'input.created_at.operator == "between"',
              name: 'to', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time',
              convert_output: 'render_iso8601_timestamp', sticky: true },
            { ngIf: 'input.created_at.operator != "between"',
              name: 'value', type: 'date_time', control_type: 'date_time',
              convert_input: 'render_epoch_time',
              convert_output: 'render_iso8601_timestamp', sticky: true }
          ] },
        { name: 'offline_payment_method', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'period_string_field_types',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed values are 'is', 'is_not', 'in', 'not_in'"
              } },
            { name: 'value', sticky: true,
              hint: "Use comma(',') separated value for 'in' and 'not_in' operator. " \
                    'e.g. value1,value2' }
          ] },
        { name: 'auto_close_invoices', type: 'object',
          properties: [
            { name: 'operator', type: 'string', sticky: true,
              control_type: 'select', pick_list: 'boolean_filter_types',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'operator',
                label: 'Operator',
                optional: true,
                sticky: true,
                type: 'string',
                control_type: 'text',
                toggle_hint: 'Use custom value',
                hint: "Allowed value: 'is'."
              } },
            { name: 'value',
              type: 'boolean', control_type: 'checkbox',
              convert_input: 'boolean_conversion',
              toggle_hint: 'Select from list',
              toggle_field: {
                name: 'value', label: 'Value',
                optional: true, sticky: true,
                type: 'string', control_type: 'text',
                convert_input: 'boolean_conversion',
                toggle_hint: 'Use custom value',
                hint: 'Allowed values are: true, false.'
              } }
          ] },
        { name: 'relationship', type: 'array', of: 'object',
          properties:
          [
            { name: 'parent_id', type: 'object',
              properties: [
                { name: 'operator', type: 'string', sticky: true,
                  control_type: 'select', pick_list: 'gateway_string_field_types',
                  toggle_hint: 'Select from list',
                  toggle_field: {
                    name: 'operator',
                    label: 'Operator',
                    optional: true,
                    sticky: true,
                    type: 'string',
                    control_type: 'text',
                    toggle_hint: 'Use custom value',
                    hint: "Allowed values are 'is', 'is_not', 'starts_with'"
                  } },
                { name: 'value', type: 'string', sticky: true }
              ] },
            { name: 'payment_owner_id', type: 'object',
              properties: [
                { name: 'operator', type: 'string', sticky: true,
                  control_type: 'select', pick_list: 'gateway_string_field_types',
                  toggle_hint: 'Select from list',
                  toggle_field: {
                    name: 'operator',
                    label: 'Operator',
                    optional: true,
                    sticky: true,
                    type: 'string',
                    control_type: 'text',
                    toggle_hint: 'Use custom value',
                    hint: "Allowed values are 'is', 'is_not', 'starts_with'"
                  } },
                { name: 'value', type: 'string', sticky: true }
              ] },
            { name: 'invoice_owner_id', type: 'object',
              properties: [
                { name: 'operator', type: 'string', sticky: true,
                  control_type: 'select', pick_list: 'gateway_string_field_types',
                  toggle_hint: 'Select from list',
                  toggle_field: {
                    name: 'operator',
                    label: 'Operator',
                    optional: true,
                    sticky: true,
                    type: 'string',
                    control_type: 'text',
                    toggle_hint: 'Use custom value',
                    hint: "Allowed values are 'is', 'is_not', 'starts_with'"
                  } },
                { name: 'value', type: 'string', sticky: true }
              ] }
          ] }
      ].
        concat(call('plan_search_input').
          only('id', 'updated_at', 'limit', 'offset', 'schema_builder'))
    end,
    customer_search_output: lambda do |input|
      [
        { name: 'customers', type: 'array', of: 'object',
          properties: call('customer_schema', input).
            concat([
                     { name: 'card', type: 'object',
                       properties: call('card_schema') }
                   ]) },
        { name: 'next_offset' }
      ]
    end,
    transaction_trigger_output: lambda do |_input|
      call('transaction_schema')
    end,
    subscription_trigger_output: lambda do |input|
      call('subscription_schema', input).
        ignored('addons', 'event_based_addons', 'payment_intent',
                'charged_event_based_addons').
        concat([{ name: 'object' },
                { name: 'card', type: 'object', properties:
                call('card_schema') },
                { name: 'customer', type: 'object', properties:
                  call('customer_schema', input).
                    concat([{ name: 'object' },
                            { name: 'card_status' }]) },
                { name: 'invoice', type: 'object', properties:
                  call('invoice_schema', '') }])
    end,
    invoice_trigger_output: lambda do |_input|
      call('invoice_schema', '')
    end,
    coupon_trigger_output: lambda do |input|
      call('coupon_schema', input).concat([{ name: 'object' }])
    end,
    order_trigger_output: lambda do |input|
      call('order_schema', input)
    end,
    quote_trigger_output: lambda do |_input|
      call('quote_schema')
    end,
    coupon_set_trigger_output: lambda do |input|
      call('coupon_set_schema', input).
        concat([
                 { name: 'coupon', type: 'object',
                   properties: call('coupon_schema', input) }
               ])
    end,
    coupon_codes_trigger_output: lambda do |input|
      call('coupon_set_schema', input).
        concat([
                 { name: 'coupon', type: 'object',
                   properties: call('coupon_schema', input) }
               ])
    end,
    differential_price_trigger_output: lambda do |input|
      call('differential_price_schema', input)
    end,
    attached_item_trigger_output: lambda do |input|
      call('attached_item_schema', input)
    end,
    item_price_trigger_output: lambda do |input|
      call('item_price_schema', input)
    end,
    item_family_trigger_output: lambda do |input|
      call('item_family_schema', input).concat([{ name: 'object' }])
    end,
    item_trigger_output: lambda do |input|
      call('item_schema', input)
    end,
    payment_trigger_output: lambda do |input|
      call('transaction_schema').
        concat([
                 { name: 'customer', type: 'object', properties:
                   call('customer_schema', '').
                     concat([{ name: 'object' },
                             { name: 'card_status' }]) },
                 { name: 'credit_note', type: 'object', properties:
                   call('credit_note_schema') },
                 { name: 'subscription', type: 'object', properties:
                   call('subscription_schema', input).
                     concat([{ name: 'object' }]) },
                 { name: 'invoice', type: 'object', properties:
                   call('invoice_schema', '') },
                 { name: 'card', type: 'object', properties:
                   call('card_schema') }
               ])
    end,
    refund_trigger_output: lambda do |_input|
      call('transaction_schema').
        concat([
                 { name: 'customer', type: 'object', properties:
                   call('customer_schema', '').
                     concat([{ name: 'object' },
                             { name: 'card_status' }]) },
                 { name: 'invoice', type: 'object', properties:
                   call('invoice_schema', '') }
               ])
    end,
    format_input: lambda do |input|
      if input.is_a?(Array)
        input.map do |array_value|
          call('format_input', array_value)
        end
      elsif input.is_a?(Hash)
        input.each_with_object({}) do |(key, value), hash|
          if value.is_a?(Array) || value.is_a?(Hash)
            if value['operator'].present? || value['sort_order'].present?
              if value['operator'] == 'between'
                hash["#{key}[#{value['operator']}]"] = "[#{value['from']},#{value['to']}]"
              elsif %w[in not_in].include?(value['operator'])
                hash["#{key}[#{value['operator']}]"] = "[#{value['value']}]"
              else
                hash["#{key}[#{value['operator'] || value['sort_order']}]"] = value['value']
              end
            else
              call('format_input', value)
            end
          else
            hash[key] = value
          end
        end
      else
        input
      end
    end
  },

  object_definitions: {
    custom_action_input: {
      fields: lambda do |connection, config_fields|
        verb = config_fields['verb']
        input_schema = parse_json(config_fields.dig('input', 'schema') || '[]')
        data_props =
          input_schema.map do |field|
            if config_fields['request_type'] == 'multipart' &&
               field['binary_content'] == 'true'
              field['type'] = 'object'
              field['properties'] = [
                { name: 'file_content', optional: false },
                {
                  name: 'content_type',
                  default: 'text/plain',
                  sticky: true
                },
                { name: 'original_filename', sticky: true }
              ]
            end
            field
          end
        data_props = call('make_schema_builder_fields_sticky', data_props)
        input_data =
          if input_schema.present?
            if input_schema.dig(0, 'type') == 'array' &&
               input_schema.dig(0, 'details', 'fake_array')
              {
                name: 'data',
                type: 'array',
                of: 'object',
                properties: data_props.dig(0, 'properties')
              }
            else
              { name: 'data', type: 'object', properties: data_props }
            end
          end

        [
          {
            name: 'path',
            hint: 'Base URI is <b>' \
            "https://#{connection['subdomain']}.chargebee.com/api/v2/" \
            '</b> - path will be appended to this URI. Use absolute URI to ' \
            'override this base URI.',
            optional: false
          },
          if %w[post put patch get].include?(verb)
            {
              name: 'request_type',
              default: 'json',
              sticky: true,
              extends_schema: true,
              control_type: 'select',
              pick_list: [
                ['JSON request body', 'json'],
                ['URL encoded form', 'url_encoded_form'],
                ['Mutipart form', 'multipart'],
                ['Raw request body', 'raw']
              ]
            }
          end,
          {
            name: 'response_type',
            default: 'json',
            sticky: false,
            extends_schema: true,
            control_type: 'select',
            pick_list: [['JSON response', 'json'], ['Raw response', 'raw']]
          },
            {
              name: 'input',
              label: 'Request body parameters',
              sticky: true,
              type: 'object',
              properties:
                if config_fields['request_type'] == 'raw'
                  [{
                    name: 'data',
                    sticky: true,
                    control_type: 'text-area',
                    type: 'string'
                  }]
                else
                  [
                    {
                      name: 'schema',
                      sticky: input_schema.blank?,
                      extends_schema: true,
                      schema_neutral: true,
                      control_type: 'schema-designer',
                      sample_data_type: 'json_input',
                      custom_properties:
                        if config_fields['request_type'] == 'multipart'
                          [{
                            name: 'binary_content',
                            label: 'File attachment',
                            default: false,
                            optional: true,
                            sticky: true,
                            convert_input: 'boolean_conversion',
                            convert_output: 'boolean_conversion',
                            control_type: 'checkbox',
                            type: 'boolean'
                          }]
                        end
                    },
                    input_data
                  ].compact
                end
            },
          {
            name: 'request_headers',
            sticky: false,
            extends_schema: true,
            control_type: 'key_value',
            empty_list_title: 'Does this HTTP request require headers?',
            empty_list_text: 'Refer to the API documentation and add ' \
            'required headers to this HTTP request',
            item_label: 'Header',
            type: 'array',
            of: 'object',
            properties: [{ name: 'key' }, { name: 'value' }]
          },
          unless config_fields['response_type'] == 'raw'
            {
              name: 'output',
              label: 'Response body',
              sticky: true,
              extends_schema: true,
              schema_neutral: true,
              control_type: 'schema-designer',
              sample_data_type: 'json_input'
            }
          end,
          {
            name: 'response_headers',
            sticky: false,
            extends_schema: true,
            schema_neutral: true,
            control_type: 'schema-designer',
            sample_data_type: 'json_input'
          }
        ].compact
      end
    },
    custom_action_output: {
      fields: lambda do |_connection, config_fields|
        response_body = { name: 'body' }

        [
          if config_fields['response_type'] == 'raw'
            response_body
          elsif (output = config_fields['output'])
            output_schema = call('format_schema', parse_json(output))
            if output_schema.dig(0, 'type') == 'array' &&
               output_schema.dig(0, 'details', 'fake_array')
              response_body[:type] = 'array'
              response_body[:properties] = output_schema.dig(0, 'properties')
            else
              response_body[:type] = 'object'
              response_body[:properties] = output_schema
            end

            response_body
          end,
          if (headers = config_fields['response_headers'])
            header_props = parse_json(headers)&.map do |field|
              if field[:name].present?
                field[:name] = field[:name].gsub(/\W/, '_').downcase
              elsif field['name'].present?
                field['name'] = field['name'].gsub(/\W/, '_').downcase
              end
              field
            end

            { name: 'headers', type: 'object', properties: header_props }
          end
        ].compact
      end
    },
    search_records_input: {
      fields: lambda do |_conneciton, config_fields|
        next [] if config_fields.blank?

        call("#{config_fields['object']}_search_input")
      end
    },
    search_records_output: {
      fields: lambda do |_conneciton, config_fields|
        next [] if config_fields.blank?

        call("#{config_fields['object']}_search_output", config_fields)
      end
    },
    get_record_input: {
      fields: lambda do |_conneciton, config_fields|
        next [] if config_fields.blank?

        call("#{config_fields['object']}_get_input")
      end
    },
    get_record_output: {
      fields: lambda do |_conneciton, config_fields|
        next [] if config_fields.blank?

        call("#{config_fields['object']}_get_output", config_fields)
      end
    },
    link_customer_output: {
      fields: lambda do |_conneciton, config_fields|
        call('customer_schema', config_fields)
      end
    },
    assign_payment_role_output: {
      fields: lambda do |_conneciton, config_fields|
        next [] if config_fields.blank?

        call('customer_schema', config_fields).
          concat([
                   { name: 'payment_source', type: 'object',
                     properties: call('payment_source_schema') }
                 ])
      end
    },
    link_customer_input: {
      fields: lambda do |_conneciton|
        [
          { name: 'customer_id', optional: false },
          { name: 'parent_id', sticky: true,
            hint: 'The ID of the customer which is to be set as the immediate parent.' },
          { name: 'payment_owner_id', sticky: true,
            hint: 'The ID of the customer who will pay the invoices for this ' \
                  'customer. Can be the child itself or the invoice_owner_id.' },
          { name: 'invoice_owner_id', sticky: true,
            hint: 'The ID of the customer who will be invoiced for charges incurred. ' \
                  'Can be the child itself or any parent in its hierarchy.' },
          { name: 'use_default_hierarchy_settings',
            type: 'boolean',
            control_type: 'checkbox',
            convert_output: 'boolean_conversion',
            toggle_hint: 'Select from list',
            convert_input: 'boolean_conversion',
            toggle_field: {
              name: 'use_default_hierarchy_settings',
              label: 'Use default hierarchy settings',
              type: 'string',
              control_type: 'text',
              optional: true,
              sticky: true,
              convert_output: 'boolean_conversion',
              convert_input: 'boolean_conversion',
              hint: 'Accepted values are true or false',
              toggle_hint: 'Use custom value'
            } },
          { name: 'parent_account_access', type: 'object',
            properties: call('parent_account_access_schema', '') },
          { name: 'child_account_access', type: 'object',
            properties: call('child_account_access_schema', '') }
        ]
      end
    },
    create_record_input: {
      fields: lambda do |_conneciton, config_fields|
        next [] if config_fields.blank?

        call("#{config_fields['object']}_create_input", config_fields)
      end
    },
    create_record_output: {
      fields: lambda do |_conneciton, config_fields|
        next [] if config_fields.blank?

        call("#{config_fields['object']}_create_output", config_fields)
      end
    },
    update_record_input: {
      fields: lambda do |_conneciton, config_fields|
        next [] if config_fields.blank?

        if config_fields['object'] == 'customer'
          call("#{config_fields['object']}_create_input", config_fields).required('id').
            ignored('billing_address', 'vat_number', 'card', 'card_status',
                    'vat_number_validated_time', 'is_location_valid',
                    'created_from_ip', 'resource_version', 'billing_date',
                    'billing_date_mode', 'billing_day_of_week', 'billing_day_of_week_mode',
                    'pii_cleared', 'primary_payment_source_id', 'backup_payment_source_id',
                    'promotional_credits', 'unbilled_charges', 'refundable_credits',
                    'excess_payments', 'deleted', 'registered_for_gst',
                    'use_default_hierarchy_settings', 'entity_identifier_scheme',
                    'entity_identifier_standard', 'is_einvoice_enabled', 'vat_number_prefix',
                    'token_id', 'business_customer_without_vat_number',
                    'payment_method', 'bank_account', 'payment_intent', 'entity_identifiers')
        else
          call("#{config_fields['object']}_update_input", config_fields)
        end
      end
    },
    update_record_output: {
      fields: lambda do |_conneciton, config_fields|
        next [] if config_fields.blank?

        if config_fields['object'] == 'customer'
          call("#{config_fields['object']}_create_output", config_fields)
        elsif config_fields['object'] == 'subscription_for_item'
          call('subscription_update_output', config_fields)
        elsif config_fields['object'] == 'invoice_detail'
          call('invoice_schema', config_fields)
        else
          call("#{config_fields['object']}_update_output", config_fields)
        end
      end
    },
    trigger_output: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        call("#{config_fields['event']}_trigger_output", config_fields)
      end
    },
    webhook_input_schema: {
      fields: lambda do |_connection, config_fields|
        next [] if config_fields.blank?

        if %w[plan addon customer subscription coupon
              item item_price].include?(config_fields['event'])
          [
            { name: 'schema_builder',
              extends_schema: true,
              control_type: 'schema-designer',
              label: 'Data fields',
              sticky: true,
              empty_schema_title: 'Describe all fields for your meta fields.',
              hint: 'A set of key-value pairs stored as additional information for ' \
                    'the object. Describe all your metadata fields.',
              optional: true,
              sample_data_type: 'json' } # json_input / xml
          ]
        else
          []
        end
      end
    },
    cancel_subscription_output: {
      fields: lambda do |_connection, config_fields|
        call('subscription_update_output', config_fields)
      end
    },
    cancel_subscription_input: {
      fields: lambda do |_connection, _config_fields|
        [
          { name: 'subscription_id', optional: false },
          { name: 'end_of_term',
            optional: true, sticky: true,
            type: 'boolean', control_type: 'checkbox',
            convert_input: 'boolean_conversion',
            toggle_hint: 'Select from list',
            hint: 'Set this to true if you want to cancel the ' \
                  'subscription at the end of the current subscription ' \
                  'billing cycle. The subscription status changes ' \
                  'to non_renewing.',
            toggle_field: {
              name: 'end_of_term', label: 'End of term',
              type: 'string', control_type: 'text',
              optional: true, sticky: true,
              convert_input: 'boolean_conversion',
              hint: 'Accepted values are true or false',
              toggle_hint: 'Use custom value'
            } },
          { name: 'cancel_at', sticky: true,
            type: 'date_time', control_type: 'date_time',
            convert_input: 'render_epoch_time',
            convert_output: 'render_iso8601_timestamp',
            hint: 'Specify the date/time at which you want to cancel ' \
                  'the subscription. This parameter should not be provided ' \
                  'when end_of_term is passed as true. cancel_at can be ' \
                  'set to a value in the past. Refer ' \
                  "<a href='https://apidocs.chargebee.com/docs/api/" \
                  "subscriptions?prod_cat_ver=1#cancel_a_subscription' " \
                   "target='_blank' >API documentation</a> for more information." },
          { name: 'credit_option_for_current_term_charges',
            sticky: true, control_type: 'select',
            pick_list: %w[none prorate full].map { |e| [e.labelize, e] },
            hint: 'For immediate cancellation (end_of_term = false), specify ' \
                  'how to provide credits for current term charges. When ' \
                  'not provided, the site default is considered.',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'credit_option_for_current_term_charges',
              label: 'Credit option for current term charges',
              optional: true, sticky: true,
              type: 'string', control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are <b>none, prorate, full</b>.'
            } },
          { name: 'unbilled_charges_option',
            sticky: true, control_type: 'select',
            pick_list: %w[invoice delete].map { |e| [e.labelize, e] },
            hint: 'For immediate cancellation (end_of_term = false), specify ' \
                  'how to handle any unbilled charges. When not provided, ' \
                  'the site default is considered.',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'unbilled_charges_option',
              label: 'Unbilled charges option',
              optional: true, sticky: true,
              type: 'string', control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are <b>invoice, delete</b>.'
            } },
          { name: 'account_receivables_handling',
            sticky: true, control_type: 'select',
            pick_list: %w[no_action schedule_payment_collection write_off].
              map { |e| [e.labelize, e] },
            hint: 'Applicable when the customer has remaining refundable ' \
                  'credits(issued against online payments). If specified ' \
                  'as schedule_refund, the refund will be initiated for ' \
                  'these credits after they are applied against the ' \
                  'subscription’s past due invoices if any. Note: The ' \
                  'refunds initiated will be asynchronous. Not applicable ' \
                  "when 'end_of_term' is true.",
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'account_receivables_handling',
              label: 'Account receivables handling',
              optional: true, sticky: true,
              type: 'string', control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are <b>no_action, ' \
                    'schedule_payment_collection, write_off</b>.'
            } },
          { name: 'contract_term_cancel_option',
            sticky: true, control_type: 'select',
            pick_list: %w[terminate_immediately end_of_contract_term].
              map { |e| [e.labelize, e] },
            hint: 'Cancels the current contract term.',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'contract_term_cancel_option',
              label: 'Contract term cancel option',
              optional: true, sticky: true,
              type: 'string', control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are <b>terminate_immediately, ' \
                    'end_of_contract_term</b>.'
            } },
          { name: 'refundable_credits_handling', control_type: 'select',
            pick_list: %w[no_action schedule_refund].map { |e| [e.labelize, e] },
            sticky: true,
            hint: 'Applicable when the customer has remaining refundable ' \
                  'credits(issued against online payments). If specified ' \
                  'as schedule_refund, the refund will be initiated for ' \
                  'these credits after they are applied against the ' \
                  'subscription’s past due invoices if any. Note: ' \
                  'The refunds initiated will be asynchronous. ' \
                  "Not applicable when 'end_of_term' is true.",
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'refundable_credits_handling',
              label: 'Refundable credits handling',
              optional: true, sticky: true,
              type: 'string', control_type: 'text',
              toggle_hint: 'Use custom value',
              hint: "Allowed values are 'no_action', 'schedule_refund'"
            } },
          { name: 'invoice_date', sticky: true,
            type: 'date_time', control_type: 'date_time',
            convert_input: 'render_epoch_time',
            convert_output: 'render_iso8601_timestamp',
            hint: 'The document date displayed on the invoice PDF. ' \
                  'The default value is the current date. Provide this ' \
                  'value to backdate the invoice. Refer ' \
                  "<a href='https://apidocs.chargebee.com/docs/api/" \
                  "subscriptions?prod_cat_ver=1#cancel_a_subscription' " \
                  "target='_blank' >API documentation</a> for more information." },
          { name: 'cancel_reason_code', sticky: true,
            hint: 'Reason code for canceling the subscription. Must be one ' \
                  'from a list of reason codes set in the Chargebee app ' \
                  'in Settings > Configure Chargebee > Reason Codes > '\
                  'Subscriptions > Subscription Cancellation. Must be '\
                  'passed if set as mandatory in the app. The codes '\
                  'are case-sensitive.' },
          { name: 'event_based_addons', sticky: true,
            type: 'array', of: 'object',
            properties: [
              { name: 'id', sticky: true,
                hint: 'The unique ID of the event-based addon that ' \
                      'represents the termination fee.' },
              { name: 'quantity', sticky: true,
                type: 'integer', control_type: 'integer',
                convert_input: 'integer_conversion',
                hint: 'The quantity associated with the termination fee. ' \
                      'Applicable only when the addon for the termination ' \
                      'charge is quantity-based.' },
              { name: 'unit_price', sticky: true,
                type: 'integer', control_type: 'integer',
                convert_input: 'integer_conversion',
                hint: 'The termination fee. In case it is quantity-based, ' \
                      'this is the fee per unit.' },
              { name: 'service_period_in_days', sticky: true,
                type: 'integer', control_type: 'integer',
                convert_input: 'integer_conversion',
                hint: 'The service period of the termination fee—expressed ' \
                      'in days—starting from the current date.' }
            ] },
          { name: 'schema_builder',
            extends_schema: true,
            control_type: 'schema-designer',
            label: 'Data fields',
            sticky: true,
            empty_schema_title: 'Describe all fields for your meta fields.',
            hint: 'A set of key-value pairs stored as additional information for ' \
                  'the subscription. Describe all your metadata fields.',
            optional: true,
            sample_data_type: 'json' }
        ]
      end
    },
    close_pending_invoice_input: {
      fields: lambda do |_connection|
        [
          { name: 'invoice_id', optional: false },
          { name: 'comment', sticky: true,
            hint: 'An internal comment to be added for this operation, to ' \
                  'the invoice. This comment is displayed on the Chargebee ' \
                  'UI. It is not displayed on any customer-facing Hosted ' \
                  'Page or any document such as the Invoice PDF.' },
          { name: 'invoice_note', stick: true,
            hint: 'A note for this particular invoice. This, and all other ' \
                  'notes for the invoice are displayed on the PDF ' \
                  'invoice sent to the customer.' },
          { name: 'remove_general_note', sticky: true,
            type: 'boolean', control_type: 'checkbox',
            convert_input: 'boolean_conversion',
            hint: 'Set as yes to remove the general note from this invoice.',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'remove_general_note', label: 'Remove general note',
              type: 'string', control_type: 'text',
              optional: true, sticky: true,
              convert_input: 'boolean_conversion',
              hint: 'Accepted values are true or false. Set as true to ' \
                    'remove the general note from this invoice.',
              toggle_hint: 'Use custom value' }
          },
          { name: 'invoice_date',
            type: 'date_time',
            control_type: 'date_time',
            convert_input: 'render_iso8601_timestamp',
            hint: 'Can only be passed when override invoice date is ' \
                  'enabled for the site.' },
          { name: 'notes_to_remove', type: 'array', of: 'object',
            sticky: true,
            item_label: 'Notes to remove',
            add_item_label: 'Add notes to remove',
            empty_list_title: 'Notes to remove list is empty',
            properties: [
              { name: 'entity_type', control_type: 'select', sticky: true,
                pick_list: %w[customer subscription coupon plan_item_price
                              addon_item_price charge_item_price].
                                map { |e| [e.labelize, e] },
                hint: 'Type of entity to which the note belongs. To remove ' \
                      'the general note, use the remove general note parameter.',
                toggle_hint: 'Select from list',
                toggle_field: {
                  name: 'entity_type', label: 'Entity type',
                  optional: true, sticky: true,
                  type: 'string', control_type: 'text',
                  toggle_hint: 'Use custom value',
                  hint: 'Type of entity to which the note belongs. To ' \
                        'remove the general note, use the ' \
                        'remove general note parameter. Allowed values are ' \
                        "'customer', 'subscription', 'coupon', " \
                        "'plan_item_price', 'addon_item_price', 'charge_item_price'"
                } },
              { name: 'entity_id', sticky: true,
                hint: 'Unique identifier of the note.' }
            ] }
        ]
      end
    },
    close_pending_invoice_output: {
      fields: lambda do |_connection|
        call('invoice_schema', '')
      end
    }
  },

  actions: {
    search_objects: {
      title: 'Search records',
      subtitle: 'Retrieve a list of records, e.g. customers, that matches ' \
                'your search criteria',
      description: lambda do |_connection, search_object_list|
        "Search <span class='provider'>" \
        "#{search_object_list[:object] || 'records'}</span> " \
        'in <span class="provider">Chargebee</span>'
      end,
      help: 'The Search records action returns results that match all your search' \
            ' criteria.',
      config_fields: [
        { name: 'object',
          optional: false,
          control_type: 'select',
          pick_list: :search_object_list,
          hint: 'Select any Chargebee object, e.g. <b>customers</b>' }
      ],
      input_fields: lambda do |object_definitions|
        object_definitions['search_records_input']
      end,
      execute: lambda do |_connection, input|
        params = call('format_input', input)
        response = if input['object'] == 'invoice_payments'
                     get("invoices/#{input['invoice_id']}/payments", params.except('object', 'invoice_id'))
                   else
                     get(input['object']&.pluralize, params.except('object'))
        end.
                   after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
        object_name = if input['object'] == 'invoice_payments'
                        'transaction'
                      else
                        input['object']
                      end
        { object_name.pluralize => response['list']&.map do |item|
          item[object_name].merge(item.except(object_name))
        end }.merge({ 'next_offset' => response['next_offset'] })
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['search_records_output']
      end,
      sample_output: lambda do |_connection, input|
        response = if input['object'] == 'invoice_payments'
                     get('transactions').params(limit: 1)
                   else
                     get(input['object']&.pluralize).params(limit: 1)
        end
        object_name = input['object'] == 'invoice_payments' ? 'transaction' : input['object']
        { object_name.pluralize => response['list']&.map do |item|
          item[object_name].merge(item.except(object_name))
        end }.merge({ 'next_offset' => response['next_offset'] })
      end
    },
    get_object: {
      title: 'Get record details by ID',
      subtitle: 'Retrieves a specific record, e.g. <b>customer</b> via its Chargebee ID',
      description: lambda do |_connection, get_object_list|
        "Get <span class='provider'>" \
        "#{get_object_list[:object] || 'record'}</span> " \
        'in <span class="provider">Chargebee</span>'
      end,
      help: 'Retrieve the details of any standard or custom record, e.g. customer, via its Chargebee ID',
      config_fields: [
        { name: 'object',
          optional: false,
          control_type: 'select',
          pick_list: :get_object_list,
          hint: 'Select any Chargebee object, e.g. <b>customer</b>' }
      ],
      input_fields: lambda do |object_definitions|
        object_definitions['get_record_input']
      end,
      execute: lambda do |_connection, input|
        response = if input['object'] == 'advance_invoice'
                     get("subscriptions/#{input['id']}/retrieve_advance_invoice_schedule")
                   elsif input['object'] == 'hierarchy'
                     get("customers/#{input['customer_id']}/hierarchy", input.except('customer_id'))
                   else
                     get("#{input['object']&.pluralize}/#{input['id']}")
        end.
                   after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
        if %w[hierarchy advance_invoice].include?(input['object'])
          response
        else
          response[input['object']]&.merge(response.except(input['object']))
        end
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['get_record_output']
      end,
      sample_output: lambda do |_connection, input|
        response = if input['object'] == 'advance_invoice'
                     { "advance_invoice_schedules": [
                       {
                         "id": '__test__KyVkmQSCX2wUp4H',
                         "object": 'advance_invoice_schedule',
                         "schedule_type": 'specific_dates',
                         "specific_dates_schedule": {
                           "date": 1_518_339_710,
                           "object": 'specific_dates_schedule',
                           "terms_to_charge": 2
                         }
                       }
                     ] }
                   elsif input['object'] == 'hierarchy'
                     {
                       "hierarchies": [
                         {
                           "object": 'hierarchy',
                           "customer_id": '3',
                           "children_ids": [
                             'AzqYOoSS8DVJR3hm'
                           ],
                           "payment_owner_id": '3',
                           "invoice_owner_id": '3'
                         }
                       ]
                     }
                   else
                     get(input['object']&.pluralize)&.
                       params(limit: 1)&.dig('list', 0)
        end
        if %w[hierarchy advance_invoice].include?(input['object'])
          response
        else
          response[input['object']]&.merge(response.except(input['object']))
        end
      end
    },
    create_object: {
      title: 'Create record',
      subtitle: 'Creates a record, e.g. <b>customer</b> in Chargebee',
      description: lambda do |_connection, create_object_list|
        "Create <span class='provider'>" \
        "#{create_object_list[:object] || 'record'}</span> " \
        'in <span class="provider">Chargebee</span>'
      end,
      help: 'Create any standard or custom record, e.g. customer, in Chargebee',
      config_fields: [
        { name: 'object',
          optional: false,
          control_type: 'select',
          pick_list: :create_object_list,
          hint: 'Select any Chargebee object, e.g. <b>customer</b>' }
      ],
      input_fields: lambda do |object_definitions|
        object_definitions['create_record_input']
      end,
      execute: lambda do |_connection, input|
        input = call('format_create_input', input)
        if input['meta_data'].present?
          input['meta_data'] = input['meta_data'].to_json
        end
        response = if input['object'] == 'subscription_for_item'
                     post("customers/#{input.delete('customer_id')}/subscription_for_items").params(input.except('object', 'schema_builder'))
                   elsif input['object'] == 'subscription_for_customer'
                     post("customers/#{input.delete('customer_id')}/subscriptions").params(input.except('object', 'schema_builder'))
                   elsif input['object'] == 'quote_for_update_subscription_item'
                     post('quotes/update_subscription_quote_for_items').params(input.except('object', 'schema_builder'))
                   elsif input['object'] == 'invoice_charge'
                    post('invoices/charge').params(input.except('object', 'schema_builder')).headers('Content-Type': 'application/x-www-form-urlencoded')
                   else
                     post(input['object'].pluralize).params(input.except('object', 'schema_builder')).headers('Content-Type': 'application/x-www-form-urlencoded')
                   end&.
                   after_error_response(/.*/) do |_code, body, _header, message|
                     error("#{message}: #{body}")
                   end
        if %w[subscription_for_item subscription_for_customer].include?(input['object'])
          input['object'] = 'subscription'
        end
        response[input['object']]&.merge(response.except(input['object']))
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['create_record_output']
      end,
      sample_output: lambda do |_connection, input|
        response = if %w[subscription_for_item subscription_for_customer].include?(input['object'])
                     get('subscriptions')&.
                       params(limit: 1)&.dig('list', 0)
                   else
                     get(input['object']&.pluralize)&.
                       params(limit: 1)&.dig('list', 0)
                   end
        if %w[subscription_for_item subscription_for_customer].include?(input['object'])
          input['object'] = 'subscription'
        end
        response[input['object']]&.merge(response.except(input['object']))
      end
    },
    update_object: {
      title: 'Update record',
      subtitle: 'Update any standard or custom record, e.g. customer, via its Chargebee ID',
      description: lambda do |_connection, update_object_list|
        "Update <span class='provider'>" \
        "#{update_object_list[:object] || 'record'}</span> " \
        'in <span class="provider">Chargebee</span>'
      end,
      help: 'Update any standard or custom record, e.g. customer, via its Chargebee ID. ' \
            'First select the object, then specify the Chargebee ID of the record to update',
      config_fields: [
        { name: 'object',
          optional: false,
          control_type: 'select',
          pick_list: :update_object_list,
          hint: 'Select any Chargebee object, e.g. <b>customer</b>' }
      ],
      input_fields: lambda do |object_definitions|
        object_definitions['update_record_input']
      end,
      execute: lambda do |_connection, input|
        input = call('format_create_input', input)
        if input['meta_data'].present?
          input['meta_data'] = input['meta_data'].to_json
        end
        response = if input['object'] == 'hierarchy_access_setting'
                     post("customers/#{input.delete('customer_id')}/update_hierarchy_settings").params(input.except('object', 'schema_builder'))
                   elsif input['object'] == 'subscription_for_item'
                     post("subscriptions/#{input['subscription_id']}/update_for_items").params(input.except('object', 'schema_builder'))
                   elsif input['object'] == 'invoice_detail'
                     post("invoices/#{input['invoice_id']}/update_details").params(input.except('object', 'schema_builder'))
                   elsif input['object'] == 'quote_for_update_subscription_item'
                     post("quotes/#{input.delete('quote_id')}/edit_update_subscription_quote_for_items").params(input.except('object', 'schema_builder'))
                   else
                     post("#{input['object'].pluralize}/#{input['id']}").params(input.except('object', 'schema_builder'))
        end&.
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
        if input['object'] == 'hierarchy_access_setting'
          input['object'] = 'customer'
        elsif input['object'] == 'invoice_detail'
          input['object'] = 'invoice'
        end
        response[input['object']]&.merge(response.except(input['object']))
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['update_record_output']
      end,
      sample_output: lambda do |_connection, input|
        response = if input['object'] == 'hierarchy_access_setting'
                     get('customers')&.
                       params(limit: 1)&.dig('list', 0)
                   else
                     get(input['object']&.pluralize)&.
                       params(limit: 1)&.dig('list', 0)
        end
        if input['object'] == 'hierarchy_access_setting'
          input['object'] = 'customer'
        end
        response[input['object']]&.merge(response.except(input['object']))
      end
    },
    link_customer: {
      title: 'Link customer',
      subtitle: 'Link customer in Chargebee',
      description: lambda do |_connection|
        "Link <span class='provider'>customer</span> " \
        'in <span class="provider">Chargebee</span>'
      end,
      help: 'Sets a customer into a hierarchical relationship with another.',
      input_fields: lambda do |object_definitions|
        object_definitions['link_customer_input']
      end,
      execute: lambda do |_connection, input|
        input = call('format_create_input', input)
        post("customers/#{input.delete('customer_id')}/relationships").params(input).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end&.[]('customer')
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['link_customer_output']
      end,
      sample_output: lambda do |_connection, _input|
        get('customers').params(limit: 1)&.dig('list', 0)
      end
    },
    delink_customer: {
      title: 'Delink customer',
      subtitle: 'Delink customer in Chargebee',
      description: lambda do |_connection|
        "Delink <span class='provider'>customer</span> " \
        'in <span class="provider">Chargebee</span>'
      end,
      help: 'Disconnects a child customer from its parent.',
      input_fields: lambda do |_object_definitions|
        [
          { name: 'customer_id', optional: false }
        ]
      end,
      execute: lambda do |_connection, input|
        input = call('format_create_input', input)
        post("customers/#{input.delete('customer_id')}/delete_relationship").
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end&.[]('customer')
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['link_customer_output']
      end,
      sample_output: lambda do |_connection, _input|
        get('customers').params(limit: 1)&.dig('list', 0)
      end
    },
    assign_payment_role: {
      title: 'Assign payment role',
      subtitle: 'Assign payment role in Chargebee',
      description: lambda do |_connection|
        "Assign <span class='provider'>payment role</span> " \
        'in <span class="provider">Chargebee</span>'
      end,
      help: 'Assign Primary or Backup payment role or unassign role for the ' \
            'payment source based on the preference for the payment collection.',
      input_fields: lambda do |_object_definitions|
        [
          { name: 'customer_id', optional: false },
          { name: 'payment_source_id', optional: false },
          { name: 'role', optional: false,
            control_type: 'select', pick_list: 'role_list',
            toggle_hint: 'Select from list',
            toggle_field: {
              name: 'role', label: 'Role',
              type: 'string', control_type: 'text',
              optional: false,
              toggle_hint: 'Use custom value',
              hint: 'Allowed values are <b>primary, backup, none</b>'
            } }
        ]
      end,
      execute: lambda do |_connection, input|
        input = call('format_create_input', input)
        response = post("customers/#{input.delete('customer_id')}/assign_payment_role").params(input).
                   after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
        response['customer']&.merge(response.except('customer'))
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['assign_payment_role_output']
      end,
      sample_output: lambda do |_connection, _input|
        response = get('customers').params(limit: 1)&.dig('list', 0)
        response['customer']&.merge(response.except('customer'))
      end
    },
    custom_action: {
      subtitle: 'Build your own Chargebee action with a HTTP request',

      description: lambda do |object_value, _object_label|
        "<span class='provider'>" \
        "#{object_value[:action_name] || 'Custom action'}</span> in " \
        "<span class='provider'>Chargebee</span>"
      end,

      help: {
        body: 'Build your own Chargebee action with a HTTP request. ' \
        'The request will be authorized with your Chargebee connection.',
        learn_more_url: 'https://apidocs.chargebee.com/docs/api',
        learn_more_text: 'Chargebee API documentation'
      },

      config_fields: [
        {
          name: 'action_name',
          hint: "Give this action you're building a descriptive name, e.g. " \
          'create record, get record',
          default: 'Custom action',
          optional: false,
          schema_neutral: true
        },
        {
          name: 'verb',
          label: 'Method',
          hint: 'Select HTTP method of the request',
          optional: false,
          control_type: 'select',
          pick_list: %w[get post put patch options delete].
            map { |verb| [verb.upcase, verb] }
        }
      ],

      input_fields: lambda do |object_definition|
        object_definition['custom_action_input']
      end,

      execute: lambda do |_connection, input|
        verb = input['verb']
        if %w[get post put patch options delete].exclude?(verb)
          error("#{verb.upcase} not supported")
        end
        path = input['path']
        data = input.dig('input', 'data') || {}
        if input['request_type'] == 'multipart'
          data = data.each_with_object({}) do |(key, val), hash|
            hash[key] = if val.is_a?(Hash)
                          [val[:file_content],
                           val[:content_type],
                           val[:original_filename]]
                        else
                          val
                        end
          end
        end
        request_headers = input['request_headers']
          &.each_with_object({}) do |item, hash|
          hash[item['key']] = item['value']
        end || {}
        request = case verb
                  when 'get'
                    get(path, data)
                  when 'post'
                    if input['request_type'] == 'raw'
                      post(path).request_body(data)
                    else
                      post(path, data)
                    end
                  when 'put'
                    if input['request_type'] == 'raw'
                      put(path).request_body(data)
                    else
                      put(path, data)
                    end
                  when 'patch'
                    if input['request_type'] == 'raw'
                      patch(path).request_body(data)
                    else
                      patch(path, data)
                    end
                  when 'options'
                    options(path, data)
                  when 'delete'
                    delete(path, data)
                  end.headers(request_headers)
        request = case input['request_type']
                  when 'url_encoded_form'
                    request.request_format_www_form_urlencoded
                  when 'multipart'
                    request.request_format_multipart_form
                  else
                    request
                  end
        response =
          if input['response_type'] == 'raw'
            request.response_format_raw
          else
            request
          end.
          after_error_response(/.*/) do |code, body, headers, message|
            error({ code: code, message: message, body: body, headers: headers }.
              to_json)
          end

        response.after_response do |_code, res_body, res_headers|
          {
            body: res_body ? call('format_response', res_body) : nil,
            headers: res_headers
          }
        end
      end,

      output_fields: lambda do |object_definition|
        object_definition['custom_action_output']
      end
    },
    cancel_subscription: {
      title: 'Cancel a subscription',
      subtitle: 'Cancel a subscription in Chargebee',
      description: lambda do |_connection|
        "Cancel a <span class='provider'>subscription</span> " \
        'in <span class="provider">Chargebee</span>'
      end,
      help: 'Cancelling a subscription will move the subscription ' \
            'from its current state to Cancelled, and will ' \
            'stop all recurring actions.',
      input_fields: lambda do |object_definitions|
        object_definitions['cancel_subscription_input']
      end,
      execute: lambda do |_connection, input|
        input = call('format_create_input', input)
        response = post("subscriptions/#{input.delete('subscription_id')}/cancel").
                   params(input.except('schema_builder')).
                   after_error_response(/.*/) do |_code, body, _header, message|
          error("#{message}: #{body}")
        end
        response['subscription']&.merge(response.except('subscription'))
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['cancel_subscription_output']
      end,
      sample_output: lambda do |_connection, _input|
        response = get('subscriptions').params(limit: 1)&.dig('list', 0)
        response['subscription']&.merge(response.except('subscription'))
      end
    },
    close_pending_invoice: {
      title: 'Close a pending invoice',
      subtitle: 'Close a pending invoice in Chargebee',
      description: lambda do |_connection|
        "Close a <span class='provider'>Pending invoice</span> " \
        'in <span class="provider">Chargebee</span>'
      end,
      help: 'Invoices for a subscription are created with a pending status ' \
            'when the subscription has create_pending_invoices attribute set ' \
            'to true. This action finalizes a pending invoice. Any ' \
            'refundable credits and excess payments for the customer are ' \
            'applied to the invoice, and any payment due is collected ' \
            'automatically if auto_collection is on for the customer.',
      input_fields: lambda do |object_definition|
        object_definition['close_pending_invoice_input']
      end,
      output_fields: lambda do |object_definition|
        object_definition['close_pending_invoice_output']
      end,
      execute: lambda do |_connection, input|
        post("invoices/#{input.delete('invoice_id')}/close").params(input).
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end&.dig('invoice') || {}
      end,
      sample_output: lambda do
        get('invoices?limit=1')&.dig('list', 0, 'invoice')
      end
    },
    download_invoice: {
      title: 'Download invoice as PDF',
      subtitle: 'Download invoice as PDF in Chargebee',
      description: lambda do |_connection|
        "Download <span class='provider'>Invoice as PDF</span> " \
        'in <span class="provider">Chargebee</span>'
      end,
      help: 'Gets the invoice as PDF. The binary contents will be ' \
            'downloaded from the download URL',
      input_fields: lambda do |_object_definition|
        [
          { name: 'invoice_id', optional: false }
        ]
      end,
      execute: lambda do |_connection, input|
        response = post("invoices/#{input.delete('invoice_id')}/pdf").
          after_error_response(/.*/) do |_code, body, _header, message|
            error("#{message}: #{body}")
          end
        { file_content: get(response&.dig('download', 'download_url')).response_format_raw.
            after_error_response(/.*/) do |_code, body, _header, message|
              error("#{message}: #{body}")
            end }
      end,
      output_fields: lambda do |object_definition|
        [
          { name: 'file_content', label: 'File contents' }
        ]
      end,
      summarize_output: ['file_content'],
      sample_output: lambda do
        {
          "file_content": "123xxxxxabxyz"
        }
      end
    }
  },

  webhook_keys: lambda do |_params, _headers, payload|
    payload['event_type']
  end,
  triggers: {
    new_event: {
      title: 'New event',
      subtitle: 'Monitor a new event in Chargebee. <b>e.g. Plan created.</b>',
      description: lambda do |_connection, input|
        event = input['event_type'].present? ? "(#{input['event_type']})" : ''
        "New event <span class='provider'>" \
        "#{event} </span> in <span class='provider'>Chargebee</span>"
      end,
      help: 'Triggers immediately as soon as trigger events, e.g. plan created, occurs. ',
      config_fields: [
        { name: 'event', label: 'Object',
          optional: false,
          control_type: 'select',
          change_on_blur: true,
          hint: 'Select any standard Chargebee object.',
          pick_list: 'event_trigger_list' },
        { name: 'event_type',
          label: 'Event type',
          optional: false,
          change_on_blur: true,
          ngIf: 'input.event',
          control_type: 'select',
          hint: 'Select a specific event type.',
          pick_list: 'event_type_trigger_list',
          pick_list_params: { event: 'event' } }
      ],
      input_fields: lambda do |object_definitions|
        object_definitions['webhook_input_schema']
      end,
      webhook_key: lambda do |_connection, input|
        input['event_type']
      end,
      webhook_notification: lambda do |input, payload|
        response = payload['content']&.merge('webhook_id' => (payload['id'] || Time.now.to_f).to_s)
        if %w[payment refund].include?(input['event'])
          response['transaction']&.merge(response&.except('transaction'))
        elsif input['event'] == 'coupon_codes'
          response['coupon_set']&.merge(response&.except('coupon_set'))
        else
          response[input['event']]&.merge(response&.except(input['event']))
        end
      end,
      dedup: lambda do |event|
        event['webhook_id']
      end,
      output_fields: lambda do |object_definitions|
        object_definitions['trigger_output']
      end,
      sample_output: lambda do |_connection, input|
        response = get("events?limit=1&event_type[is]=#{input['event_type']}")&.dig('list', 0, 'event', 'content')
        if %w[payment refund].include?(input['event'])
          response['transaction']&.merge(response&.except('transaction'))
        elsif input['event'] == 'coupon_codes'
          response['coupon_set']&.merge(response&.except('coupon_set'))
        else
          response[input['event']]&.merge(response&.except(input['event']))
        end
      end
    }
  },

  pick_lists: {
    event_trigger_list: lambda do |_connection|
      [
        %w[Plan plan],
        %w[Add-on addon],
        %w[Customer customer],
        %w[Credit\ note credit_note],
        %w[Transaction transaction],
        %w[Subscription subscription],
        %w[Invoice invoice],
        %w[Payment payment],
        %w[Refund refund],
        %w[Item item],
        %w[Item\ Family item_family],
        %w[Item\ Price item_price],
        %w[Attached\ item attached_item],
        %w[Differential\ price differential_price],
        %w[Coupon coupon],
        %w[Coupon\ set coupon_set],
        %w[Coupon\ codes coupon_codes],
        %w[Order order],
        %w[Quote quote]
      ]
    end,
    event_type_trigger_list: lambda do |_connection, event:|
      case event
      when 'plan'
        [
          %w[Plan\ created plan_created],
          %w[Plan\ updated plan_updated],
          %w[Plan\ deleted plan_deleted]
        ]
      when 'addon'
        [
          %w[Add-on\ created addon_created],
          %w[Add-on\ updated addon_updated],
          %w[Add-on\ deleted addon_deleted]
        ]
      when 'customer'
        [
          %w[Customer\ created customer_created],
          %w[Customer\ changed customer_changed],
          %w[Customer\ deleted customer_deleted]
        ]
      when 'credit_note'
        [
          %w[Credit\ note\ created credit_note_created],
          %w[Credit\ note\ updated credit_note_updated],
          %w[Credit\ note\ deleted credit_note_deleted]
        ]
      when 'transaction'
        [
          %w[Transaction\ created transaction_created],
          %w[Transaction\ updated transaction_updated],
          %w[Transaction\ deleted transaction_deleted]
        ]
      when 'refund'
        [
          %w[Refund\ initiated refund_initiated]
        ]
      when 'subscription'
        [
          %w[Subscription\ created subscription_created],
          %w[Subscription\ activated subscription_activated],
          %w[Subscription\ changed subscription_changed],
          %w[MRR\ updated mrr_updated],
          %w[Subscription\ cancelled subscription_cancelled],
          %w[Subscription\ reactivated subscription_reactivated],
          %w[Subscription\ renewal\ reminder subscription_renewal_reminder]
        ]
      when 'invoice'
        [
          %w[Pending\ invoice\ created pending_invoice_created],
          %w[Pending\ invoice\ updated pending_invoice_updated],
          %w[Invoice\ generated invoice_generated],
          %w[Invoice\ updated invoice_updated],
          %w[Invoice\ deleted invoice_deleted]
        ]
      when 'payment'
        %w[payment_succeeded payment_failed payment_refunded payment_initiated].
          map { |e| [e.labelize, e] }
      when 'order'
        %w[order_created order_updated order_cancelled order_delivered
           order_returned order_ready_to_process order_ready_to_ship
           order_deleted].map { |e| [e.labelize, e] }
      when 'quote'
        %w[quote_created quote_updated quote_deleted].map { |e| [e.labelize, e] }
      when 'coupon'
        %w[coupon_created coupon_updated coupon_deleted].map { |e| [e.labelize, e] }
      when 'coupon_set'
        %w[coupon_set_created coupon_set_updated coupon_set_deleted].map { |e| [e.labelize, e] }
      when 'coupon_codes'
        %w[coupon_codes_added coupon_codes_updated coupon_codes_deleted].map { |e| [e.labelize, e] }
      when 'item'
        %w[item_created item_updated item_deleted].map { |e| [e.labelize, e] }
      when 'item_family'
        %w[item_family_created item_family_updated item_family_deleted].
          map { |e| [e.labelize, e] }
      when 'item_price'
        %w[item_price_created item_price_updated item_price_deleted].
          map { |e| [e.labelize, e] }
      when 'attached_item'
        %w[attached_item_created attached_item_updated attached_item_deleted].
          map { |e| [e.labelize, e] }
      when 'differential_price'
        %w[differential_price_created differential_price_updated differential_price_deleted].
          map { |e| [e.labelize, e] }
      end
    end,
    search_object_list: lambda do |_connection|
      [
        %w[Plans plan],
        %w[Add-ons addon],
        %w[Customers customer],
        %w[Subscriptions subscription],
        %w[Invoices invoice],
        %w[Credit\ notes credit_note],
        %w[Transactions transaction],
        %w[Payments\ for\ an\ invoice invoice_payments],
        %w[Coupons coupon],
        %w[Items item],
        %w[Item\ prices item_price]
      ]
    end,
    get_object_list: lambda do |_connection|
      [
        %w[Plan plan],
        %w[Addon addon],
        %w[Customer customer],
        %w[Subscription subscription],
        %w[Invoice invoice],
        %w[Credit\ note credit_note],
        %w[Transaction transaction],
        %w[Advance\ invoice\ schedules advance_invoice],
        %w[Coupon coupon],
        %w[Item item],
        %w[Item\ price item_price],
        %w[Hierarchy hierarchy]
      ]
    end,
    create_object_list: lambda do |_connection|
      %w[customer subscription_for_customer subscription_for_item
         credit_note invoice invoice_charge quote_for_update_subscription_item comment].
        map { |e| [e.labelize, e] }
    end,
    update_object_list: lambda do |_connection|
      %w[customer subscription hierarchy_access_setting
         subscription_for_item invoice_detail
         quote_for_update_subscription_item].map { |e| [e.labelize, e] }
    end,
    auto_collection_list: lambda do |_connection|
      [%w[On on], %w[Off off]]
    end,
    offline_payment_method_list: lambda do |_connection|
      [
        %w[No\ preference no_preference],
        %w[Cash cash],
        %w[Check check],
        %w[Bank\ transfer bank_transfer],
        %w[ACH\ credit ach_credit],
        %w[SEPA\ credit sepa_credit]
      ]
    end,
    taxjar: lambda do |_connection|
      [
        %w[Wholesale wholesale],
        %w[Government government],
        %w[Other other]
      ]
    end,
    avalara_sale_type: lambda do
      %w[wholesale retail consumed vendor_use].map { |e| [e.labelize, e] }
    end,
    vat_number_status_list: lambda do |_connection|
      [
        %w[Valid valid],
        %w[Invalid invalid],
        %w[Not\ validated not_validated],
        %w[Undetermined undetermined]
      ]
    end,
    taxability_list: lambda do |_connection|
      [
        %w[Taxable taxable],
        %w[Exempt exempt]
      ]
    end,
    entity_code_list: lambda do |_connection|
      [
        %w[Federal\ government a],
        %w[State\ government b],
        %w[Tribe/Status\ Indian/Indian\ Band c],
        %w[Foreign\ diplomat d],
        %w[Charitable\ or\ benevolent\ organization e],
        %w[Religious\ organization f],
        %w[Resale g],
        %w[Commercial\ agricultural\ production h],
        %w[Industrial\ production/manufacturer i],
        %w[Direct\ pay\ permit j],
        %w[Direct\ mail k],
        %w[Other\ or\ custom l],
        %w[Educational\ organization m],
        %w[Local\ government n],
        %w[Commercial\ aquaculture p],
        %w[Commercial\ Fishery q],
        %w[Non\ resident r],
        %w[US\ Medical\ Device\ Excise\ Tax\ with\ exempt\ sales\ tax med1],
        %w[US\ Medical\ Device\ Excise\ Tax\ with\ taxable\ sales\ tax med2]
      ]
    end,
    billing_date_mode_list: lambda do |_connection|
      [
        %w[Using\ defaults using_defaults],
        %w[Manually\ set manually_set]
      ]
    end,
    billing_day_of_week_list: lambda do |_connection|
      [
        %w[Sunday sunday],
        %w[Monday monday],
        %w[Tuesday tuesday],
        %w[Wednesday wednesday],
        %w[Thursday thursday],
        %w[Friday friday],
        %w[Saturday saturday]
      ]
    end,
    billing_day_of_week_mode_list: lambda do |_connection|
      [
        %w[Using\ defaults using_defaults],
        %w[Manually\ set manually_set]
      ]
    end,
    pii_cleared_list: lambda do |_connection|
      [
        %w[Active active],
        %w[Scheduled\ For\ Clear scheduled_for_clear],
        %w[Cleared cleared]
      ]
    end,
    type_list: lambda do |_connection|
      [
        %w[Authorization authorization],
        %w[Payment payment],
        %w[Refund refund],
        %w[Payment\ reversal payment_reversal]
      ]
    end,
    fraud_flag_list: lambda do |_connection|
      [
        %w[Safe safe],
        %w[Suspicious suspicious],
        %w[Fraudulent fraudulent]
      ]
    end,
    customer_fraud_flag_list: lambda do |_connection|
      [
        %w[Safe safe],
        %w[Fraudulent fraudulent]
      ]
    end,
    customer_type_list: lambda do |_connection|
      [
        %w[Residential residential],
        %w[Business business],
        %w[Senior\ citizen senior_citizen],
        %w[Industrial industrial]
      ]
    end,
    validation_status_list: lambda do |_connection|
      [
        %w[Not\ validated not_validated],
        %w[Valid valid],
        %w[Partially\ valid partially_valid],
        %w[Invalid invalid]
      ]
    end,
    referral_system_list: lambda do |_connection|
      [
        %w[Referral\ candy referral_candy],
        %w[Feferral\ saasquatch referral_saasquatch],
        %w[Friend\ buy friendbuy]
      ]
    end,
    payment_method_type_list: lambda do |_connection|
      [
        %w[Card card],
        %w[Paypal\ express\ checkout paypal_express_checkout],
        %w[Amazon\ payments amazon_payments],
        %w[Direct\ debit direct_debit],
        %w[Generic generic],
        %w[Alipay alipay],
        %w[Unionpay unionpay],
        %w[Apple\ pay apple_pay],
        %w[Wechat\ pay wechat_pay],
        %w[IDEAL ideal],
        %w[Google\ pay google_pay],
        %w[Sofort sofort],
        %w[Bancontact bancontact],
        %w[giropay giropay],
        %w[Dotpay dotpay]
      ]
    end,
    payment_method_gateway_list: lambda do |_connection|
      [
        %w[Chargebee chargebee],
        %w[Stripe stripe],
        %w[WePay wepay],
        %w[Braintree braintree],
        %w[Authorize.net authorize_net],
        %w[Paypal\ pro paypal_pro],
        %w[Pin pin],
        %w[eWAY eway],
        %w[eWAY\ Rapid eway_rapid],
        %w[WorldPay worldpay],
        %w[Balanced\ payment balanced_payments],
        %w[Beanstream beanstream],
        %w[Bluepay bluepay],
        %w[Elavon elavon],
        %w[First\ Data\ Global first_data_global],
        %w[HDFC hdfc],
        %w[MasterCard\ Internet\ Gateway\ Service migs],
        %w[NMI nmi],
        %w[Ingenico\ ePayments\ (formerly\ Ogone) ogone],
        %w[PAYMILL paymill],
        %w[PayPal\ Payflow\ Pro paypal_payflow_pro],
        %w[Sage\ Pay sage_pay],
        %w[2Checkout tco],
        %w[WireCard wirecard],
        %w[The\ amazon\ payments amazon_payments],
        %w[The\ paypal paypal_express_checkout],
        %w[GoCardless gocardless],
        %w[Adyen adyen],
        %w[Chase\ Paymentech(Orbital) orbital],
        %w[Moneris\ USA moneris_us],
        %w[Moneris moneris],
        %w[BlueSnap bluesnap],
        %w[CyberSource cybersource],
        %w[Vantiv vantiv],
        %w[Checkout.com checkout_com],
        %w[Paypal\ Commerce paypal],
        %w[Ingenico\ ePayments ingenico_direct],
        %w[Not\ applicable not_applicable],
        %w[Mollie mollie]
      ]
    end,
    payment_source_status_list: lambda do |_connection|
      [
        %w[Valid valid],
        %w[Expiring expiring],
        %w[Expired expired],
        %w[Invalid invalid],
        %w[Pending\ verification pending_verification]
      ]
    end,
    portal_edit_child_subscriptions_list: lambda do |_connection|
      [
        %w[Yes yes],
        %w[View\ only view_only],
        %w[No no]
      ]
    end,
    portal_edit_subscriptions_list: lambda do |_connection|
      [
        %w[Yes yes],
        %w[View\ only view_only]
      ]
    end,
    portal_download_invoices_list: lambda do |_connection|
      [
        %w[Yes yes],
        %w[View\ only view_only],
        %w[No no]
      ]
    end,
    id_string_field_types: lambda do
      %w[is is_not starts_with in not_in].map { |e| [e.labelize, e] }
    end,
    name_string_field_types: lambda do
      %w[is is_not starts_with].map { |e| [e.labelize, e] }
    end,
    subscription_id_string_field_types: lambda do
      %w[is is_not starts_with is_present in not_in].map { |e| [e.labelize, e] }
    end,
    dunning_string_field_types: lambda do
      %w[is is_not is_present in not_in].map { |e| [e.labelize, e] }
    end,
    gateway_string_field_types: lambda do
      %w[is is_not starts_with].map { |e| [e.labelize, e] }
    end,
    string_filter_types: lambda do
      %w[is is_not starts_with is_present].map { |e| [e.labelize, e] }
    end,
    period_string_field_types: lambda do
      %w[is is_not in not_in].map { |e| [e.labelize, e] }
    end,
    number_filter_types: lambda do
      [
        %w[Is is],
        %w[Is\ not is_not],
        %w[Less\ than lt],
        %w[Less\ than\ or\ equal\ to lte],
        %w[Greater\ than gt],
        %w[Greater\ than\ or\ equal\ to gte],
        %w[Between between]
      ]
    end,
    trial_number_filter_types: lambda do
      [
        %w[Is is],
        %w[Is\ not is_not],
        %w[Less\ than lt],
        %w[Less\ than\ or\ equal\ to lte],
        %w[Greater\ than gt],
        %w[Greater\ than\ or\ equal\ to gte],
        %w[Between between],
        %w[Is\ present is_present]
      ]
    end,
    period_unit: lambda do
      %w[day week month year].map { |e| [e.labelize, e] }
    end,
    trial_period_unit: lambda do
      %w[day month].map { |e| [e.labelize, e] }
    end,
    addon_applicability: lambda do
      %w[all restricted].map { |e| [e.labelize, e] }
    end,
    boolean_filter_types: lambda do
      [
        %w[Is is]
      ]
    end,
    pricing_model: lambda do
      %w[flat_fee per_unit tiered volume stairstep].map { |e| [e.labelize, e] }
    end,
    status: lambda do
      %w[active archived].map { |e| [e.labelize, e] }
    end,
    item_status: lambda do
      %w[active deleted].map { |e| [e.labelize, e] }
    end,
    item_price_status: lambda do
      %w[active archived deleted].map { |e| [e.labelize, e] }
    end,
    price_type: lambda do
      [
        %w[Tax\ inclusive tax_inclusive],
        %w[Tax\ exclusive tax_exclusive]
      ]
    end,
    tax_type: lambda do
      [
        %w[Taxable taxable],
        %w[Exempt exempt]
      ]
    end,
    subscription_string_filter_types: lambda do
      %w[is is_not in not_in is_present].map { |e| [e.labelize, e] }
    end,
    cancel_reason_value: lambda do
      %w[not_paid no_card fraud_review_failed non_compliant_eu_customer
         tax_calculation_failed currency_incompatible_with_gateway
         non_compliant_customer].map { |e| [e.labelize, e] }
    end,
    reason_code_list: lambda do
      %w[write_off subscription_change subscription_cancellation subscription_pause
         chargeback product_unsatisfactory service_unsatisfactory order_change
         order_cancellation waiver other fraudulent].map { |e| [e.labelize, e] }
    end,
    credit_note_reason_code: lambda do
      %w[product_unsatisfactory service_unsatisfactory order_change
         order_cancellation waiver other].map { |e| [e.labelize, e] }
    end,
    credit_note_status: lambda do
      %w[adjusted refunded refund_due voided].map { |e| [e.labelize, e] }
    end,
    invoice_status: lambda do
      %w[paid posted payment_due not_paid voided pending].map { |e| [e.labelize, e] }
    end,
    credit_note_type_list: lambda do
      %w[adjustment refundable].map { |e| [e.labelize, e] }
    end,
    timestamp_filter_types: lambda do
      %w[after between on before].map { |e| [e.labelize, e] }
    end,
    charge_type: lambda do
      %w[recurring non_recurring].map { |e| [e.labelize, e] }
    end,
    card_status_list: lambda do
      %w[valid expiring expired].map { |e| [e.labelize, e] }
    end,
    card_type_list: lambda do
      %w[visa mastercard american_express discover jcb diners_club other].
        map { |e| [e.labelize, e] }
    end,
    funding_type_list: lambda do
      %w[credit debit prepaid not_known].map { |e| [e.labelize, e] }
    end,
    powered_by_list: lambda do
      %w[ideal sofort bancontact giropay not_applicable].map { |e| [e.labelize, e] }
    end,
    attribute_list: lambda do
      %w[created_at updated_at].map { |e| [e.labelize, e] }
    end,
    invoice_attribute_list: lambda do
      %w[date updated_at].map { |e| [e.labelize, e] }
    end,
    sort_order_list: lambda do
      [
        %w[Ascending asc],
        %w[Descending desc]
      ]
    end,
    dunning_status_value: lambda do
      %w[in_progress exhausted stopped success].map { |e| [e.labelize, e] }
    end,
    transaction_status_value: lambda do
      %w[in_progress voided failure success needs_attention timeout].map { |e| [e.labelize, e] }
    end,
    subscription_status: lambda do
      %w[future in_trial active non_renewing paused cancelled].map { |e| [e.labelize, e] }
    end,
    payment_gateway_list: lambda do
      %w[chargebee stripe wepay braintree authorize_net paypal_pro pin eway
         eway_rapid worldpay balanced_payments beanstream bluepay elavon
         first_data_global hdfc migs nmi ogone paymill paypal_payflow_pro
         sage_pay tco wirecard amazon_payments paypal_express_checkout gocardless
         adyen orbital moneris_us moneris bluesnap cybersource vantiv checkout_com
         paypal ingenico_direct not_applicable].map { |e| [e.labelize, e] }
    end,
    payment_method_list: lambda do
      %w[card cash check chargeback bank_transfer amazon_payments
         paypal_express_checkout direct_debit alipay unionpay apple_pay
         wechat_pay ach_credit sepa_credit ideal google_pay sofort bancontact
         giropay dotpay other].map { |e| [e.labelize, e] }
    end,
    hierarchy_operation_type: lambda do
      %w[complete_hierarchy subordinates path_to_root].map { |e| [e.labelize, e] }
    end,
    item_type: lambda do
      %w[plan addon charge].map { |e| [e.labelize, e] }
    end,
    usage_calculation: lambda do
      %w[sum_of_usages last_usage].map { |e| [e.labelize, e] }
    end,
    auto_collection: lambda do
      %w[on off].map { |e| [e.labelize, e] }
    end,
    billing_alignment_mode: lambda do
      %w[immediate delayed].map { |e| [e.labelize, e] }
    end,
    discount_type: lambda do
      %w[fixed_amount percentage].map { |e| [e.labelize, e] }
    end,
    duration_type: lambda do
      %w[one_time forever limited_period].map { |e| [e.labelize, e] }
    end,
    coupon_status: lambda do
      %w[active expired archived deleted].map { |e| [e.labelize, e] }
    end,
    apply_on: lambda do
      %w[invoice_amount each_specified_item].map { |e| [e.labelize, e] }
    end,
    on_event: lambda do
      %w[subscription_creation subscription_trial_start plan_activation
         subscription_activation contract_termination].map { |e| [e.labelize, e] }
    end,
    charge_on: lambda do
      %w[immediately on_event].map { |e| [e.labelize, e] }
    end,
    action_at_term_end: lambda do
      %w[renew cancel].map { |e| [e.labelize, e] }
    end,
    quote_action_at_term_end: lambda do
      %w[renew cancel renew_once].map { |e| [e.labelize, e] }
    end,
    role_list: lambda do
      %w[primary backup none].map { |e| [e.labelize, e] }
    end,
    account_type: lambda do
      %w[checking savings business_checking].map { |e| [e.labelize, e] }
    end,
    account_holder_type: lambda do
      %w[individual company].map { |e| [e.labelize, e] }
    end,
    echeck_type: lambda do
      %w[web ppd ccd].map { |e| [e.labelize, e] }
    end,
    entity_type: lambda do
      %w[plan addon customer subscription coupon].map { |e| [e.labelize, e] }
    end,
    comment_entity_type: lambda do
      %w[customer subscription coupon invoice quote credit_note transaction
        plan addon order item_family item item_price].map { |e| [e.labelize, e] }
    end,
    trial_end_action_list: lambda do
      %w[site_default plan_default activate_subscription cancel_subscription].
        map { |e| [e.labelize, e] }
    end,
    channel_type: lambda do
      %w[app_store play_store].map { |e| [e.labelize, e] }
    end
  }
}



