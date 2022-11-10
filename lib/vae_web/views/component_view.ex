defmodule VaeWeb.ComponentView do
  use VaeWeb, :view

  @tracking_config Application.get_env(:vae, :tracking)

  def render("back_button", %{conn: conn} = params) do
    referer = case Plug.Conn.get_req_header(conn, "referer") do
      [("http" <> referer_url) = hd | _] when not is_nil(referer_url) -> hd
      _ -> nil
    end
    home_page = Routes.root_path(conn, :index)
    to = params[:to] || referer || params[:default_to] || home_page
    label = params[:label] || (if URI.parse(to).path === home_page, do: "Retour à l'accueil", else: "Retour")
    Phoenix.HTML.Link.link(label, to: to, class: "button is-back #{params[:class]}")
  end

  # @deprecated use tag_commander to manage scripts with cookies
  def render("analytics", %{conn: conn}) do
    dimension1 =
      case conn.remote_ip do
        {109, 26, 209, n} when n >= 86 and n <= 89 -> "true"
        _ -> "false"
      end

    has_analytics = @tracking_config[:analytics]
    has_optimize = @tracking_config[:optimize]

    (List.wrap(
       if has_optimize,
         do: [
           """
             <!-- Google Optimize -->
             <style>.async-hide { opacity: 0 !important} </style>
             <script>(function(a,s,y,n,c,h,i,d,e){s.className+=' '+y;h.start=1*new Date;
             h.end=i=function(){s.className=s.className.replace(RegExp(' ?'+y),'')};
             (a[n]=a[n]||[]).hide=h;setTimeout(function(){i();h.end=null},c);h.timeout=c;
             })(window,document.documentElement,'async-hide','dataLayer',4000,
             {'#{@tracking_config[:optimize]}':true});</script>
             <!-- End Google Optimize -->
           """
         ]
     ) ++
       List.wrap(
         if has_analytics,
           do: [
             """
               <!-- Google Analytics -->
               <script>
               (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
               (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
               m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
               })(window,document,'script','https://www.google-analytics.com/analytics#{
               if Mix.env() == :dev, do: "_debug"
             }.js','ga');
             """,
             """
               ga('create', '#{@tracking_config[:analytics]}', 'auto');
             """,
             if(@tracking_config[:analytics_bis],
               do: "ga('create', '#{@tracking_config[:analytics_bis]}', 'auto');"
             ),
             if(@tracking_config[:optimize],
               do: "ga('require', '#{@tracking_config[:optimize]}');"
             ),
             """
               ga('set', 'dimension1', '#{dimension1}');
               ga('send', 'pageview');

               window.disableGa = function() {
                 window['ga-disable-#{@tracking_config[:analytics]}'] = true;
             """,
             if(@tracking_config[:analytics_bis],
               do: "window['ga-disable-#{@tracking_config[:analytics_bis]}'] = true;"
             ),
             """
               };
               </script>
               <!-- End Google Analytics -->
             """
           ]
       ))
    |> Enum.filter(fn el -> el end)
    |> Enum.join("\n")
    |> Phoenix.HTML.raw()
  end

  # @deprecated use tag_commander to manage scripts with cookies
  def render("hotjar", _) do
    if @tracking_config[:hotjar] do
      {:safe, """
        <script type=\"text/javascript\">
          var now = new Date(); var expires= new Date(now.setFullYear(now.getFullYear()+1));
          var cookie = `TC_CONFIG={"hotjar_key": "@tracking_config[:hotjar]"}; expires=${expires.toUTCString()}; path=/`;
          document.cookie = cookie;
        </script>
      """}
    end
  end

  # @deprecated use tag_commander to manage scripts with cookies
  def render("crisp", _) do
    if @tracking_config[:crisp] do
      {:safe,
       """
         <script type="text/javascript">
         window.$crisp=[];
         window.CRISP_WEBSITE_ID='#{@tracking_config[:crisp]}';
         (function(){
           d=document;s=d.createElement("script");
           s.src="https://client.crisp.chat/l.js";s.async=1;
           d.getElementsByTagName("head")[0].appendChild(s);
         })();
         </script>
       """}
    end
  end

  def render("tag_commander", _) do
    if @tracking_config[:tag_commander] do
      url = "https://cdn.tagcommander.com#{@tracking_config[:tag_commander]}.js"

      {:safe, "<script type=\"text/javascript\" src=\"#{url}\" async></script>"}
    end
  end
end
