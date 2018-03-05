describe HostedDanger::Envs do
  it "setup (dev)" do
    setup_envs_dev do
      HostedDanger::Envs.setup
      HostedDanger::Envs.get("access_token_ghe").should eq("dummy_ghe")
      HostedDanger::Envs.get("access_token_partner").should eq("dummy_partner")
      HostedDanger::Envs.get("access_token_git").should eq("dummy_git")
      HostedDanger::Envs.get("dragon_access_key").should eq("dragon_key")
      HostedDanger::Envs.get("dragon_secret_access_key").should eq("dragon_secret_key")
    end
  end

  it "setup (prod)" do
    setup_envs_prod do
      HostedDanger::Envs.get("access_token_ghe").should eq("dummy_ghe")
      HostedDanger::Envs.get("access_token_partner").should eq("dummy_partner")
      HostedDanger::Envs.get("access_token_git").should eq("dummy_git")
      HostedDanger::Envs.get("dragon_access_key").should eq("dragon_key")
      HostedDanger::Envs.get("dragon_secret_access_key").should eq("dragon_secret_key")

      ENV["ACCESS_TOKEN_GHE"]?.should be_nil
      ENV["ACCESS_TOKEN_PARTNER"]?.should be_nil
      ENV["ACCESS_TOKEN_GIT"]?.should be_nil
      ENV["DRAGON_ACCESS_KEY"]?.should be_nil
      ENV["DRAGON_SECRET_ACCESS_KEY"]?.should be_nil
    end
  end
end
