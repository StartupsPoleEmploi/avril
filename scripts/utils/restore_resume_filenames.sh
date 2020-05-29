#!/bin/bash

export COMPOSE_INTERACTIVE_NO_CLI=1

BUCKET_NAME=${1?"BUCKET_NAME required"}

PHOENIX_CONTAINER_ID=$(docker ps -a | grep phoenix | cut -d' ' -f1)
MINIO_CONTAINER_ID=$(docker ps -a | grep minio | cut -d' ' -f1)

update_file_url() {
  RESUME_ID=${1?"RESUME_ID required"}
  FILENAME=${2?"FILENAME required"}

read -r -d '' ELIXIR_UPDATE_COMMAND << EOM
resume = Vae.Repo.get(Vae.Resume, $RESUME_ID) |> Vae.Repo.preload(:application)
resume
|> Vae.Resume.changeset(%{url: String.replace(resume.url, resume.filename, "$FILENAME")})
|> Vae.Repo.update()
EOM

  docker exec $PHOENIX_CONTAINER_ID mix run -e "$ELIXIR_UPDATE_COMMAND"
}

get_filename() {
  RESUME_ID=${1?"RESUME_ID required"}
  APPLICATION_ID=${2?"APPLICATION_ID required"}
  MODIFICATION_TIME=${3?"MODIFICATION_TIME required"}

  LIST_FILE_COMMAND="ls -Al -t --full-time /data/$BUCKET_NAME/$APPLICATION_ID | grep '$MODIFICATION_TIME' | rev | cut -d' ' -f1 | rev"

  docker exec $MINIO_CONTAINER_ID sh -c "mkdir -p /data/$BUCKET_NAME/$APPLICATION_ID"
  FILENAME=$(docker exec $MINIO_CONTAINER_ID sh -c "$LIST_FILE_COMMAND");

  if [ $(echo "$FILENAME" | wc -l) -gt 1 ];
  then
    echo ":( Multiple entries, need to manual match for application_id $APPLICATION_ID"
  fi
  FILENAME=${FILENAME//[$'\t\r\n']} # Remove new lines
  if [[ ! -z "$FILENAME" ]]; then
    echo ":) $FILENAME found for resume ID: $RESUME_ID"
    update_file_url "$RESUME_ID" "$FILENAME";
  else
    echo ":( File not found for resume ID: $RESUME_ID"
  fi

}

select_resumes() {

read -r -d '' ELIXIR_SELECT_COMMAND << EOM
import Ecto.Query

date = ~N[2020-05-14 22:51:44]
id_min=9244
id_max=9529
query =
  from r in Vae.Resume, [
    where: not like(r.url, "https://avril.pole-emploi.fr/files/%/________________________________.%") and not like(r.url, "https://avril.pole-emploi.fr/files/%/________________________________"),
    order_by: [desc: :inserted_at]
  ]

Vae.Repo.all(query) |> Enum.each(fn r ->
  IO.write("|")
  r.id
  |> Integer.to_string()
  |> String.replace_suffix("", "|")
  |> IO.write()

  r.application_id
  |> Integer.to_string()
  |> String.replace_suffix("", "|")
  |> IO.write()

  r.inserted_at
  |> NaiveDateTime.add(-1)
  |> Timex.format!("%Y-%m-%d %H:%M:%S", :strftime)
  |> String.replace_suffix("", "\n")
  |> IO.write()
end)
EOM

  docker exec $PHOENIX_CONTAINER_ID mix run -e "$ELIXIR_SELECT_COMMAND" | while read RESUME_INFOS; do
    RESUME_ID=$(echo $RESUME_INFOS | cut -d '|' -s -f2)
    APPLICATION_ID=$(echo $RESUME_INFOS | cut -d '|' -s -f3)
    MODIFICATION_TIME=$(echo $RESUME_INFOS | cut -d '|' -s -f4)

    if [[ ! -z "$RESUME_ID" ]] && [[ ! -z "$APPLICATION_ID" ]] && [[ ! -z "$MODIFICATION_TIME" ]]; then
      echo "Searching for : resume ID: $RESUME_ID app_id: $APPLICATION_ID modif_time: $MODIFICATION_TIME";
      get_filename "$RESUME_ID" "$APPLICATION_ID" "$MODIFICATION_TIME";
    fi
  done
}

rename_resumes() {

read -r -d '' ELIXIR_RENAME_COMMAND << EOM
import Ecto.Query

id_min=9244
id_max=9529

query =
  from r in Vae.Resume, [
    where: r.id >= ^id_min and r.id <= ^id_max and not like(r.filename, "%|%"),
    order_by: [desc: :inserted_at]
  ]

Vae.Repo.all(query) |> Enum.each(fn r ->
  application_id = r.application_id
  previous_filename = r.filename
  new_filename = "#{UUID.uuid4(:hex)}#{Path.extname(r.filename)}"

  IO.write("|#{application_id}|#{previous_filename}|#{new_filename}\n")

  r
  |> Vae.Repo.preload(:application)
  |> Vae.Resume.changeset(%{url: Vae.Resume.file_url(Vae.URI.endpoint(), application_id, new_filename)})
  |> Vae.Repo.update()
end)
EOM

  docker exec $PHOENIX_CONTAINER_ID mix run -e "$ELIXIR_RENAME_COMMAND" | while read RESUME_INFOS; do
    APPLICATION_ID=$(echo $RESUME_INFOS | cut -d '|' -s -f2)
    PREVIOUS_FILENAME=$(echo $RESUME_INFOS | cut -d '|' -s -f3)
    NEW_FILENAME=$(echo $RESUME_INFOS | cut -d '|' -s -f4)

    if [[ ! -z "$APPLICATION_ID" ]] && [[ ! -z "$PREVIOUS_FILENAME" ]] && [[ ! -z "$NEW_FILENAME" ]]; then
      echo "Renaming for : app_id: $APPLICATION_ID previous_name: $PREVIOUS_FILENAME new_name: $NEW_FILENAME";

      RENAME_FILE_COMMAND="mv \"/data/$BUCKET_NAME/$APPLICATION_ID/$PREVIOUS_FILENAME\" \"/data/$BUCKET_NAME/$APPLICATION_ID/$NEW_FILENAME\""

      docker exec $MINIO_CONTAINER_ID sh -c "$RENAME_FILE_COMMAND" && echo "$PREVIOUS_FILENAME renamed";
    fi
  done

}

check_resumes() {
  read -r -d '' ELIXIR_CHECK_COMMAND << EOM
import Ecto.Query

query =
  from r in Vae.Resume, [
    order_by: [desc: :inserted_at]
  ]

Vae.Repo.all(query) |> Enum.each(fn r ->
  IO.write("|#{r.id}|#{r.application_id}|#{r.url}\n")
end)
EOM

  docker exec $PHOENIX_CONTAINER_ID mix run -e "$ELIXIR_CHECK_COMMAND" | while read RESUME_INFOS; do
    RESUME_ID=$(echo $RESUME_INFOS | cut -d '|' -s -f2)
    APPLICATION_ID=$(echo $RESUME_INFOS | cut -d '|' -s -f3)
    URL=$(echo $RESUME_INFOS | cut -d '|' -s -f4)

    if [[ ! -z "$RESUME_ID" ]] && [[ ! -z "$APPLICATION_ID" ]] && [[ ! -z "$URL" ]]; then

      status_code=$(curl --write-out %{http_code} --silent --output /dev/null $URL)

      if [[ "$status_code" -ne 200 ]] ; then
        echo "FILE NOT FOUND"
        echo "APPLICATION_ID: $APPLICATION_ID"
        echo "RESUME_ID: $RESUME_ID"
      fi
    fi
  done
}

# select_resumes
# rename_resumes
check_resumes