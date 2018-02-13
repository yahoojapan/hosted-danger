require "./spec_helper"

describe HostedDanger do

  it "successfully build" do
    proj_root = File.expand_path("../..", __FILE__)

    Dir.cd(proj_root) do
      system("shards build").should eq(true)
    end
  end
end

require "./units/*"
