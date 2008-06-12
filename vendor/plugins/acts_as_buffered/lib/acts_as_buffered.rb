module Acts #:nodoc:
  # Specify this act if you want changes to your model to be buffered
  # for large commits. 
  #
  #   class Foo < ActiveRecord::Base
  #     acts_as_buffered
  #   end
  #
  # See <tt>Acts::Buffered::ClassMethods#acts_as_buffered</tt>
  # for configuration options
  module Buffered #:nodoc: 
        
    def self.included(base) # :nodoc:
      base.extend ClassMethods
    end

    module ClassMethods
      
      def acts_as_buffered(options = {})
        # don't allow multiple calls
        return if self.included_modules.include?(Acts::Buffered::InstanceMethods)

        include Acts::Buffered::InstanceMethods
        
        class_eval do
          extend Acts::Buffered::SingletonMethods
          
          cattr_accessor :buffering_enabled
          cattr_accessor :ignore_primary_key
          cattr_accessor :composite_primary_key
    
          self.buffering_enabled = true
          self.composite_primary_key = ! self.primary_key.is_a?(String)  
          self.ignore_primary_key = options[:ignore_primary_key]
          self.ignore_primary_key = false if self.ignore_primary_key.nil?                  
        end
      end

    end

    module InstanceMethods
      
      # Temporarily turns off buffering while saving.
      def save_without_buffering
        without_buffering do
          save
        end
      end

      # Executes the block with the buffering callbacks disabled.
      #
      #   @foo.without_buffering do
      #     @foo.save
      #   end
      #
      def without_buffering(&block)
        self.class.without_buffering(&block)
      end

      #overload save
      def save 
        self.buffering_enabled ? buffered_create : create_or_update
      end

      #overload save!
      def save! 
        self.buffering_enabled ? (buffered_create || raise(RecordNotSaved)) : (create_or_update  || raise(RecordNotSaved))
      end
      
      def commit
        buffered_commit
      end
      
      def disable_keys
        connection.execute("ALTER TABLE #{self.class.table_name} DISABLE KEYS")
      end
      
      def enable_keys
        connection.execute("ALTER TABLE #{self.class.table_name} ENABLE KEYS")
      end   
      
      def after_initialize
        @create_buffer = ""
        @create_buffer_count = 0          
      end
     
      def buffer_count
        @create_buffer_count
      end   

      def buffer_empty?
        @create_buffer_count == 0
      end   

      def next_buffered_id   
        unless self.ignore_primary_key || self.composite_primary_key
          if @create_buffer_count == 0 || self.id.nil?
            self.id = self.class.find(:first, :order => "#{self.class.primary_key} DESC").id unless self.class.count == 0
            self.id = 0 if self.id.nil?
          end  
          self.id = self.id + 1 
        end  
      end
      
      private
        def buffered_create
          raise ReadOnlyRecord if readonly?
          next_buffered_id
          @create_buffer << "," unless @create_buffer_count == 0
          @create_buffer << "(#{attributes_with_quotes(!self.ignore_primary_key).values.join(', ')})"
          @create_buffer_count = @create_buffer_count + 1          
          true
        end
        
        def buffered_commit 
          if (@create_buffer_count > 0)
            begin 
              connection.execute("LOCK TABLES #{self.class.table_name} WRITE")
              connection.execute("INSERT INTO #{self.class.table_name} (#{quoted_column_names(attributes_with_quotes(!self.ignore_primary_key)).join(', ')}) VALUES " << @create_buffer)
            ensure
              connection.execute("UNLOCK TABLES")
              @create_buffer = ""
              @create_buffer_count = 0    
            end  
          end  
        end
        
    end # InstanceMethods
    
    module SingletonMethods
      # Executes the block with the buffering callbacks disabled.
      #
      #   Foo.without_buffering do
      #     @foo.save
      #   end
      #
      def without_buffering(&block)
        buffering_was_enabled = buffering_enabled
        disable_buffering
        returning(block.call) { enable_buffering if buffering_was_enabled }
      end
      
      def disable_buffering
        self.buffering_enabled = false
      end
      
      def enable_buffering
        self.buffering_enabled = true
      end
    end    
  end  
end
