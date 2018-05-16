use Mix.Config

deploy_server = System.get_env("DEPLOY_SERVER")
import_config "#{deploy_server}.exs" 
