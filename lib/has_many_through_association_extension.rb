require 'active_record'

# NOTE: this fix also needs to be made in the composite_primary_keys plugin if you are using it
module ActiveRecord
  module Associations
    class HasManyThroughAssociation < HasManyAssociation #:nodoc:
      def construct_joins(custom_joins = nil)       
        polymorphic_join = nil
        if @reflection.source_reflection.macro == :belongs_to
          reflection_primary_key = @reflection.klass.primary_key
          source_primary_key     = @reflection.source_reflection.primary_key_name
          if @reflection.options[:source_type]
            polymorphic_join = "AND %s.%s = %s" % [
              @reflection.through_reflection.quoted_table_name, "#{@reflection.source_reflection.options[:foreign_type]}",
              @owner.class.quote_value(@reflection.options[:source_type])
            ]
          end
        else
          reflection_primary_key = @reflection.source_reflection.primary_key_name
          # I think that it is using the wrong key
          # There is no way to override this broken behavior because there is no support for foreign_key as an option
          # Add in the check for foreign key. This makes the behavior match the :include behavior for the same association
          source_primary_key = @reflection.options[:foreign_key] || @reflection.klass.primary_key
          if @reflection.source_reflection.options[:as]
            polymorphic_join = "AND %s.%s = %s" % [
              @reflection.quoted_table_name, "#{@reflection.source_reflection.options[:as]}_type",
              @owner.class.quote_value(@reflection.through_reflection.klass.name)
            ]
          end
        end        
        "INNER JOIN %s ON %s.%s = %s.%s %s #{@reflection.options[:joins]} #{custom_joins}" % [
          @reflection.through_reflection.table_name,
          @reflection.table_name, reflection_primary_key,
          @reflection.through_reflection.table_name, source_primary_key,
          polymorphic_join
        ]
      end
    end
  end  
end