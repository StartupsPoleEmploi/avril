defmodule Vae.CampaignDiffuser.FileExtractor do
  @type path :: String.t()
  @type job_seeker :: Map.t()

  # @doc "Extract data"
  # @callback extract() :: [job_seeker()]
  # @callback build_enumerable() :: [job_seeker()]
  # @callback extract_lines_flow() :: [job_seeker()]
  # @callback build_job_seeker_flow() :: [job_seeker()]
  # @callback add_geolocation_flow() :: [job_seeker()]
end
