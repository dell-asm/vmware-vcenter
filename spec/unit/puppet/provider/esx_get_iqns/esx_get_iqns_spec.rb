require 'spec_helper'
require 'yaml'
require 'puppet/provider/vcenter'

#require 'rspec/mocks'
require 'fixtures/unit/puppet/provider/esx_get_iqns/esx_get_iqns_fixture'
require 'mocha'
describe "Get iqns operation testing for esx" do
  before(:each) do
    @fixture = Esx_get_iqns_fixture.new
    @fixture.provider.stubs(:get_iqn)
  end

  context "when esx_get_iqns provider is executed " do
    it "should have a get_esx_iqns method defined for esx_get_iqns" do
      @fixture.provider.class.instance_method(:get_esx_iqns).should_not == nil
    end

    it "should have a parent 'Puppet::Provider::Vcentre'" do
      @fixture.provider.should be_kind_of(Puppet::Provider::Vcenter)
    end
  end

  context "when esx_get_iqns is created " do
    it "should return list of iqns" do
      #Then
      list = Array.new

      @fixture.provider.stubs(:get_iqn_from_host).returns{list}
      # @fixture.provider.should eql(:get_iqn)
      # @fixture.provider.should eql(:get_iqn).once.with(list).ordered
      #When
      #  @fixture.provider.get_esx_iqns
    end
  end
end



