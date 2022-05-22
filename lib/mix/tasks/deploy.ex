defmodule Mix.Tasks.Deploy do
  use Mix.Task
  import System, only: [cmd: 3]

  @shortdoc "Build a Phoenix project locally and deploy it"
  def run([application, remote_location]) do
    :ssh.start()

    [host, remote_path] = String.split(remote_location, ":")

    [
      "mix deps.get --only prod",
      "mix compile",
      # add a flag on whether this and assets.deploy are needed
      "mix phx.digest.clean --all",
      "mix assets.deploy",
      "mix release --overwrite",
      "tar -zcf _build/prod/#{application}.tar.gz _build/prod/rel/#{application}/",
      "scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null _build/prod/#{application}.tar.gz #{host}:/tmp/#{application}.tar.gz"
    ]
    |> Enum.each(fn command ->
      IO.puts(">> #{command}")
      [command | args] = String.split(command, " ")
      cmd(command, args, env: [{"MIX_ENV", "prod"}])
    end)

    # make a flag for ignore hosts
    {:ok, conn} = :ssh.connect(to_charlist(host), 22, silently_accept_hosts: true)
    conn
    |> ssh(host, "mkdir -p /tmp/#{application}/")
    |> ssh(host, "tar -zxf /tmp/#{application}.tar.gz -C /tmp/#{application}/")
    # add chown as an option to this
    |> ssh(host, "sudo rsync -a /tmp/#{application}/_build/prod/rel/#{application}/ #{remote_path}")
    |> ssh(host, "sudo systemctl restart #{application}")
    # add chown as an option to this
    # cleanup old releases (we are doing cold restarts)
    |> ssh(host, "sudo rsync -a --delete /tmp/#{application}/_build/prod/rel/#{application}/ #{remote_path}")
    |> ssh(host, "sudo rm -rf /tmp/#{application}.tar.gz /tmp/#{application}")
  end

  # there's a bug where failures in commands do not close the connection
  defp ssh(conn, host, command) do
    IO.puts("#{host} >> #{command}")
    {:ok, chan} = :ssh_connection.session_channel(conn, :infinity)
    :success = :ssh_connection.exec(conn, chan, command, :infinity)
    receive_ssh(conn)
    conn
  end

  defp receive_ssh(conn) do
    receive do
      {:ssh_cm, ^conn, {:exit_status, _, 0}} ->
        "SSH command failed"

      {:ssh_cm, ^conn, {:data, _, _, data}} ->
        IO.write(data)
        receive_ssh(conn)
    end
  end
end
