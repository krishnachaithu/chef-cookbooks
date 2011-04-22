define :django_app, :action => :deploy, :user => "root", :mode => "0755",
       :packages => {} do
  include_recipe "python"
  
  raise "Please provide the deploy details." unless params[:deploy_settings]
  
  group = (params[:group] or user)
  sites_dir = node[:sites][:dir]
  path = (params[:path] or "#{sites_dir}/#{params[:name]}")
  venvs_dir = node[:django][:virtualenvs]
  venv = (params[:virtualenv] or "#{venvs_dir}/#{params[:name]}")
  server_type = node[:django][:app_server]
  requirements = (params[:requirements] or "#{path}/code/requirements.txt")
  bin_path = (params[:manage_path] or "#{path}/code/#{params[:name]}")
  collectstatic = (params[:collectstatic] or true)

  directory path do
    owner params[:user]
    group group
    mode params[:mode]
    action :create
  end

  directory "#{path}/public" do
    owner params[:user]
    group group
    mode params[:mode]
    action :create
  end

  directory "#{path}/logs" do
    owner params[:user]
    group group
    mode params[:mode]
    action :create
  end

  directory "#{path}/backup" do
    owner params[:user]
    group group
    mode params[:mode]
    action :create
  end
  
  git "#{path}/code" do
    repository params[:deploy_settings][:repo]
    revision params[:deploy_settings][:revision]
    user params[:user]
    group group
    action :sync
  end
  
  # Avoid passing the params object directly to another custom definition - it
  # seems to cause problems.
  owner = params[:user]
  mode = params[:mode]
  packages = params[:packages]
  
  virtualenv params[:name] do
    path venv
    owner owner
    group group
    mode mode
    packages packages
    requirements requirements
  end
  
  if collectstatic
    execute "collect static media" do
      command "#{venv}/bin/python manage.py collectstatic --noinput"
      cwd "#{bin_path}"
      ignore_failure true
    end
  end
end
