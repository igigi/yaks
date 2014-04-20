require 'virtus'
require 'yaks'
require 'json'

Example = JSON.parse %q<
    {
      "posts": [{
        "id": "1",
        "title": "Rails is Omakase",
        "links": {
          "author": "http://example.com/people/1",
          "comments": "http://example.com/comments/5,12,17,20"
        }
      }]
    }
>


class Person
  include Virtus.model
  attribute :id, String
  attribute :name, String
end


class Comment
  include Virtus.model
  attribute :id, String
end

class Post
  include Virtus.model
  attribute :id, String
  attribute :title, String
  attribute :author, Person
  attribute :comments, Array[Comment]
end

class BaseMapper < Yaks::Mapper
  link :self, 'http://example.com/{plural_profile_type}/{id}'

  def plural_profile_type
    pluralize(profile_type.to_s)
  end
end

class CollectionMapper < Yaks::CollectionMapper
  link :self, 'http://example.com/{plural_profile_type}/{id*}'

  def plural_profile_type
    pluralize(profile_type.to_s)
  end
end

class CommentMapper < BaseMapper
  attributes :id
end

class PersonMapper < BaseMapper
  attributes :id, :name
end

class PostMapper < BaseMapper
  attributes :id, :title

  has_one :author, mapper: PersonMapper
  has_many :comments, mapper: CommentMapper, collection_mapper: CollectionMapper
end

post = Post.new(
  id: 1,
  title: "Rails is Omakase",
  author: Person.new(id: "1", name: "@d2h"),
  comments: [5, 12, 17, 20].map {|id| Comment.new(id: id.to_s)}
)

resource = PostMapper.new(post).to_resource

json_api = Yaks::JsonApiSerializer.new(resource, embed: :links).to_json_api

gem 'minitest'
require 'minitest/autorun'

describe('json-api') {
  specify { assert_equal Example, json_api }
}