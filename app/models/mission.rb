class Mission < ApplicationRecord
  mount_uploader :image, MissionImageUploader
  acts_as_taggable
  #mission.instances 可以列出所有本任務產生的副本
  has_many :instances
  has_many :invitations, through: :instances
end
