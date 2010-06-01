require 'spec_helper'
load_backend(:couch_rest)

describe Delayed::Backend::CouchRest::Job do
  before(:all) do
    @backend = Delayed::Backend::CouchRest::Job
  end

  before(:each) do
    @backend.delete_all
  end

  it_should_behave_like 'a backend'
end
