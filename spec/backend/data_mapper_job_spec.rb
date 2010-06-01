require 'spec_helper'
load_backend(:data_mapper)

describe Delayed::Backend::DataMapper::Job do
  before(:all) do
    @backend = Delayed::Backend::DataMapper::Job
  end

  before(:each) do
    # reset database before each example is run
    DataMapper.auto_migrate!
  end

  it_should_behave_like 'a backend'
end
