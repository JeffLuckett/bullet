module Bullet
  module Detector
    class CounterCache < Base
      class <<self
        def add_counter_cache(object, associations)
          return unless Bullet.start?
          return unless Bullet.counter_cache_enable?

          Bullet.debug("Detector::CounterCache#add_counter_cache", "object: #{object.bullet_ar_key}, associations: #{associations}")
          if conditions_met?(object.bullet_ar_key, associations)
            create_notification object.class.to_s, associations
          end
        end

        def add_possible_objects(object_or_objects)
          return unless Bullet.start?
          return unless Bullet.counter_cache_enable?

          objects = Array(object_or_objects)
          Bullet.debug("Detector::CounterCache#add_possible_objects", "objects: #{objects.map(&:bullet_ar_key).join(', ')}")
          objects.each { |object| possible_objects.add object.bullet_ar_key }
        end

        def add_impossible_object(object)
          return unless Bullet.start?
          return unless Bullet.counter_cache_enable?

          Bullet.debug("Detector::CounterCache#add_impossible_object", "object: #{object.bullet_ar_key}")
          impossible_objects.add object.bullet_ar_key
        end

        private
          def create_notification(klazz, associations)
            notify_associations = Array(associations) - Bullet.get_whitelist_associations(:counter_cache, klazz)

            if notify_associations.present?
              notice = Bullet::Notification::CounterCache.new klazz, notify_associations
              Bullet.notification_collector.add notice
            end
          end

          def possible_objects
            Thread.current[:bullet_counter_possible_objects]
          end

          def impossible_objects
            Thread.current[:bullet_counter_impossible_objects]
          end

          def conditions_met?(bullet_ar_key, associations)
            possible_objects.include?(bullet_ar_key) && !impossible_objects.include?(bullet_ar_key)
          end
      end
    end
  end
end
