class BatchesController < ApplicationController

  def enqueue
    SuperNode::Invocation.new(params).save
    head :ok
  end

end