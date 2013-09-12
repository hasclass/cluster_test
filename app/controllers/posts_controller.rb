class PostsController < ApplicationController
  def add
    post = Post.create!(:title => params.fetch(:title, "New"))
    render :text => "Post created: #{post.title}"
  end

  def index
    render :text => Post.all.map(&:title).join("\n")
  end

  def root
    render :text => "hello rails"
  end
end