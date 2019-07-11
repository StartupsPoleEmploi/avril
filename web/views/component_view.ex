defmodule Vae.ComponentView do
  use Vae.Web, :view

  def render("user_token", %{conn: conn}) do
    if is_nil(conn.assigns[:user_token]) do
      {:safe, ""}
    else
      {:safe, """
        <script>
        window.userToken = "#{conn.assigns[:user_token]}";
        </script>
      """}
    end
  end

  def render("analytics", %{conn: conn}) do
    dimension1 =
      case conn.remote_ip do
        {109, 26, 209, n} when n >= 86 and n <= 89 -> "true"
        _ -> "false"
      end

    has_analytics = System.get_env("GA_API_KEY")
    has_optimize = System.get_env("GO_TEST_KEY")

    List.wrap(if has_optimize, do: [
      """
        <!-- Google Optimize -->
        <style>.async-hide { opacity: 0 !important} </style>
        <script>(function(a,s,y,n,c,h,i,d,e){s.className+=' '+y;h.start=1*new Date;
        h.end=i=function(){s.className=s.className.replace(RegExp(' ?'+y),'')};
        (a[n]=a[n]||[]).hide=h;setTimeout(function(){i();h.end=null},c);h.timeout=c;
        })(window,document.documentElement,'async-hide','dataLayer',4000,
        {'#{System.get_env("GO_TEST_KEY")}':true});</script>
        <!-- End Google Optimize -->
      """
    ]) ++ List.wrap(if has_analytics, do: [
      """
        <!-- Google Analytics -->
        <script>
        (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
        (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
        m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
        })(window,document,'script','https://www.google-analytics.com/analytics.js','ga');

        ga('create', '#{System.get_env("GA_API_KEY")}', 'auto');
      """,
      (if System.get_env("GA_PE_API_KEY"), do: "ga('create', '#{System.get_env("GA_PE_API_KEY")}', 'auto');"),
      (if System.get_env("GO_TEST_KEY"), do: "ga('require', '#{System.get_env("GO_TEST_KEY")}');"),
      """
        ga('set', 'dimension1', '#{dimension1}');
        ga('send', 'pageview');

        window.disableGa = function() {
          window['ga-disable-#{System.get_env("GA_API_KEY")}'] = true;
      """,
      (if System.get_env("GA_PE_API_KEY"), do: "window['ga-disable-#{System.get_env("GA_PE_API_KEY")}'] = true;"),
      """
        };
        </script>
        <!-- End Google Analytics -->
      """
      ]) |> Enum.filter(fn el -> el end) |> Enum.join("\n") |> Phoenix.HTML.raw


    # {:safe, """
    #   <!-- Google Optimize -->
    #   <style>.async-hide { opacity: 0 !important} </style>
    #   <script>(function(a,s,y,n,c,h,i,d,e){s.className+=' '+y;h.start=1*new Date;
    #   h.end=i=function(){s.className=s.className.replace(RegExp(' ?'+y),'')};
    #   (a[n]=a[n]||[]).hide=h;setTimeout(function(){i();h.end=null},c);h.timeout=c;
    #   })(window,document.documentElement,'async-hide','dataLayer',4000,
    #   {'#{System.get_env("GO_TEST_KEY")}':true});</script>
    #   <!-- End Google Optimize -->
    #   <!-- Google Analytics -->
    #   <script>
    #   (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
    #   (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
    #   m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
    #   })(window,document,'script','https://www.google-analytics.com/analytics.js','ga');

    #   ga('create', '#{System.get_env("GA_API_KEY")}', 'auto');
    #   ga('create', '#{System.get_env("GA_PE_API_KEY")}', 'auto');
    #   ga('require', '#{System.get_env("GO_TEST_KEY")}');
    #   ga('set', 'dimension1', '#{dimension1}');
    #   ga('send', 'pageview');

    #   window.disableGa = function() {
    #    window['ga-disable-#{System.get_env("GA_API_KEY")}'] = true;
    #    window['ga-disable-#{System.get_env("GA_PE_API_KEY")}'] = true;
    #   };
    #   </script>
    #   <!-- End Google Analytics -->
    # """}
  end

  def render("hotjar", _) do
    if is_nil(System.get_env("HOTJAR_ID")) do
      {:safe, ""}
    else
      {:safe, """
       <!-- Hotjar Tracking Code for http://avril.pole-emploi.fr -->
       <script>
       (function(h,o,t,j,a,r){
       h.hj=h.hj||function(){(h.hj.q=h.hj.q||[]).push(arguments)};
       h._hjSettings={hjid:#{System.get_env("HOTJAR_ID")},hjsv:5};
       a=o.getElementsByTagName('head')[0];
       r=o.createElement('script');r.async=1;
       r.src=t+h._hjSettings.hjid+j+h._hjSettings.hjsv;
       a.appendChild(r);
       })(window,document,'//static.hotjar.com/c/hotjar-','.js?sv=');
       </script>
      """}
    end
  end

  def render("crisp", _) do
    if is_nil(System.get_env("HOTJAR_ID")) do
      {:safe, ""}
    else
      {:safe, """
        <script type="text/javascript">
        window.$crisp=[];
        window.CRISP_WEBSITE_ID='#{System.get_env("CRISP_WEBSITE_ID")}';
        (function(){
          d=document;s=d.createElement("script");
          s.src="https://client.crisp.chat/l.js";s.async=1;
          d.getElementsByTagName("head")[0].appendChild(s);
        })();
        </script>
      """}
    end
  end

  def render("algolia_credentials", _) do
    {:safe, """
      <script>
      window.algolia_app_id = '#{Application.get_env(:algolia, :application_id)}'
      window.algolia_search_api_key = '#{Application.get_env(:algolia, :search_api_key)}'
      window.algolia_places_app_id = '#{Application.get_env(:vae, :algolia_places_app_id)}'
      window.algolia_places_api_key = '#{Application.get_env(:vae, :algolia_places_api_key)}'
      </script>
    """}
  end
end
