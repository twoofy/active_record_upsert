module ActiveRecordUpsert
  module ActiveRecord
    module PersistenceExtensions

      def upsert(upsert_keys = nil)
        raise ::ActiveRecord::ReadOnlyRecord, "#{self.class} is marked as readonly" if readonly?
        raise ::ActiveRecord::RecordSavedError, "Can't upsert a record that has already been saved" if persisted?
        values = run_callbacks(:save) {
          run_callbacks(:create) {
            _upsert_record(changed, upsert_keys)
          }
        }
        assign_attributes(values.first.to_h)
        self
      rescue ::ActiveRecord::RecordInvalid
        false
      end

      def _upsert_record(attribute_names, upsert_keys)
        attributes_values = arel_attributes_with_values_for_create(attribute_names)
        values = self.class.unscoped.upsert(attributes_values, upsert_keys)
        @new_record = false
        values
      end

      module ClassMethods
        def upsert(attributes, &block)
          if attributes.is_a?(Array)
            attributes.collect { |hash| upsert(hash, &block) }
          else
            new(attributes, &block).upsert
          end
        end
      end
    end
  end
end
