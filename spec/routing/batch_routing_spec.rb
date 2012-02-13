require 'spec_helper'

describe "batches" do
  describe "enqueue" do
    it "should route POST /enqueue" do
      { :post => "/batch/1/enqueue" }.should route_to(:controller => "hi", :action => "hey")
    end
  end
end