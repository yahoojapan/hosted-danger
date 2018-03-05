include HostedDanger::Executor

describe HostedDanger::Executor do
  it "with_dragon_envs" do

    setup_envs_prod do
      env = {} of String => String
      env["hoge"] = "test"

      env["DRAGON_ACCESS_KEY"]?.should be_nil
      env["DRAGON_SECRET_ACCESS_KEY"]?.should be_nil

      with_dragon_envs(env) do
        env["DRAGON_ACCESS_KEY"].should eq("dragon_key")
        env["DRAGON_SECRET_ACCESS_KEY"].should eq("dragon_secret_key")
        env["hoge"].should eq("test")
      end

      env["DRAGON_ACCESS_KEY"]?.should be_nil
      env["DRAGON_SECRET_ACCESS_KEY"]?.should be_nil
    end
  end
end
