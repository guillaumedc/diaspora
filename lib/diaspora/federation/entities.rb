module Diaspora
  module Federation
    module Entities
      def self.build(entity)
        case entity
        when AccountDeletion then account_deletion(entity)
        when Comment then comment(entity)
        when Contact then contact(entity)
        when Conversation then conversation(entity)
        when Like then like(entity)
        when Message then message(entity)
        when Participation then participation(entity)
        when Photo then photo(entity)
        when PollParticipation then poll_participation(entity)
        when Profile then profile(entity)
        when Reshare then reshare(entity)
        when StatusMessage then status_message(entity)
        else
          raise DiasporaFederation::Entity::UnknownEntity, "unknown entity: #{entity.class}"
        end
      end

      def self.post(post)
        case post
        when StatusMessage
          status_message(post)
        when Reshare
          reshare(post)
        else
          raise ArgumentError, "unknown post-class: #{post.class}"
        end
      end

      def self.account_deletion(account_deletion)
        DiasporaFederation::Entities::AccountDeletion.new(
          author: account_deletion.diaspora_handle
        )
      end

      def self.comment(comment)
        DiasporaFederation::Entities::Comment.new(
          author:      comment.diaspora_handle,
          guid:        comment.guid,
          parent_guid: comment.parent_guid,
          text:        comment.text,
          parent:      related_entity(comment.parent)
        )
      end

      def self.contact(contact)
        # TODO: use DiasporaFederation::Entities::Contact
        DiasporaFederation::Entities::Request.new(
          author:    contact.user.diaspora_handle,
          recipient: contact.person.diaspora_handle
        )
      end

      def self.conversation(conversation)
        DiasporaFederation::Entities::Conversation.new(
          author:       conversation.diaspora_handle,
          guid:         conversation.guid,
          subject:      conversation.subject,
          created_at:   conversation.created_at,
          participants: conversation.participant_handles,
          messages:     conversation.messages.map {|message| message(message) }
        )
      end

      def self.like(like)
        DiasporaFederation::Entities::Like.new(
          author:      like.diaspora_handle,
          guid:        like.guid,
          parent_guid: like.parent_guid,
          positive:    like.positive,
          parent_type: like.parent.class.base_class.to_s,
          parent:      related_entity(like.parent)
        )
      end

      def self.location(location)
        DiasporaFederation::Entities::Location.new(
          address: location.address,
          lat:     location.lat,
          lng:     location.lng
        )
      end

      def self.message(message)
        DiasporaFederation::Entities::Message.new(
          author:            message.diaspora_handle,
          guid:              message.guid,
          text:              message.text,
          created_at:        message.created_at,
          parent_guid:       message.parent_guid,
          conversation_guid: message.parent_guid,
          parent:            related_entity(message.parent)
        )
      end

      def self.participation(participation)
        DiasporaFederation::Entities::Participation.new(
          author:      participation.diaspora_handle,
          guid:        participation.guid,
          parent_guid: participation.parent_guid,
          parent_type: participation.parent.class.base_class.to_s,
          parent:      related_entity(participation.parent)
        )
      end

      def self.photo(photo)
        DiasporaFederation::Entities::Photo.new(
          author:              photo.diaspora_handle,
          guid:                photo.guid,
          public:              photo.public,
          created_at:          photo.created_at,
          remote_photo_path:   photo.remote_photo_path,
          remote_photo_name:   photo.remote_photo_name,
          text:                photo.text,
          status_message_guid: photo.status_message_guid,
          height:              photo.height,
          width:               photo.width
        )
      end

      def self.poll(poll)
        DiasporaFederation::Entities::Poll.new(
          guid:         poll.guid,
          question:     poll.question,
          poll_answers: poll.poll_answers.map {|answer| poll_answer(answer) }
        )
      end

      def self.poll_answer(poll_answer)
        DiasporaFederation::Entities::PollAnswer.new(
          guid:   poll_answer.guid,
          answer: poll_answer.answer
        )
      end

      def self.poll_participation(poll_participation)
        DiasporaFederation::Entities::PollParticipation.new(
          author:           poll_participation.diaspora_handle,
          guid:             poll_participation.guid,
          parent_guid:      poll_participation.parent_guid,
          poll_answer_guid: poll_participation.poll_answer.guid,
          parent:           related_entity(poll_participation.parent)
        )
      end

      def self.profile(profile)
        DiasporaFederation::Entities::Profile.new(
          author:           profile.diaspora_handle,
          first_name:       profile.first_name,
          last_name:        profile.last_name,
          image_url:        profile.image_url,
          image_url_medium: profile.image_url_medium,
          image_url_small:  profile.image_url_small,
          birthday:         profile.birthday,
          gender:           profile.gender,
          bio:              profile.bio,
          location:         profile.location,
          searchable:       profile.searchable,
          nsfw:             profile.nsfw,
          tag_string:       profile.tag_string
        )
      end

      # @deprecated
      def self.relayable_retraction(target, sender)
        DiasporaFederation::Entities::RelayableRetraction.new(
          target_guid: target.guid,
          target_type: target.class.base_class.to_s,
          target:      related_entity(target),
          author:      sender.diaspora_handle
        )
      end

      def self.reshare(reshare)
        DiasporaFederation::Entities::Reshare.new(
          root_author:           reshare.root_diaspora_id,
          root_guid:             reshare.root_guid,
          author:                reshare.diaspora_handle,
          guid:                  reshare.guid,
          public:                reshare.public,
          created_at:            reshare.created_at,
          provider_display_name: reshare.provider_display_name
        )
      end

      def self.retraction(target)
        DiasporaFederation::Entities::Retraction.new(
          target_guid: target.is_a?(User) ? target.person.guid : target.guid,
          target_type: target.is_a?(User) ? Person.to_s : target.class.base_class.to_s,
          target:      related_entity(target),
          author:      target.diaspora_handle
        )
      end

      # @deprecated
      def self.signed_retraction(target, sender)
        DiasporaFederation::Entities::SignedRetraction.new(
          target_guid: target.guid,
          target_type: target.class.base_class.to_s,
          target:      related_entity(target),
          author:      sender.diaspora_handle
        )
      end

      def self.status_message(status_message)
        DiasporaFederation::Entities::StatusMessage.new(
          author:                status_message.diaspora_handle,
          guid:                  status_message.guid,
          raw_message:           status_message.raw_message,
          photos:                status_message.photos.map {|photo| photo(photo) },
          location:              status_message.location ? location(status_message.location) : nil,
          poll:                  status_message.poll ? poll(status_message.poll) : nil,
          public:                status_message.public,
          created_at:            status_message.created_at,
          provider_display_name: status_message.provider_display_name
        )
      end

      def self.related_entity(entity)
        DiasporaFederation::Entities::RelatedEntity.new(
          author: entity.author.diaspora_handle,
          local:  entity.author.local?,
          public: entity.respond_to?(:public?) && entity.public?,
          parent: entity.respond_to?(:parent) ? related_entity(entity.parent) : nil
        )
      end
    end
  end
end
