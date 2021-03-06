require 'sinatra/base'
require 'slim'
require 'sprockets'

module RReDisServer
  class SprocketsMiddleware
    def initialize(app, options={})
      @app = app
      @root = options[:root]
      path   =  options[:path] || 'assets'
      @matcher = /^\/#{path}\/*/
      @environment = ::Sprockets::Environment.new(@root)
      @environment.append_path 'assets/javascripts'
      @environment.append_path 'assets/javascripts/vendor'
      @environment.append_path 'assets/stylesheets'
      @environment.append_path 'assets/stylesheets/vendor'
      @environment.append_path 'assets/images'
    end

    def call(env)
      return [301, { 'Location' => "#{env['SCRIPT_NAME']}/" }, []] if env['SCRIPT_NAME'] == env['REQUEST_PATH']

      return @app.call(env) unless @matcher =~ env["PATH_INFO"]
      env['PATH_INFO'].sub!(@matcher,'')
      @environment.call(env)
    end
  end

  class Web < Sinatra::Base
    dir = File.expand_path(File.dirname(__FILE__) + "/web")
    set :views,  "#{dir}/views"
    set :root, "#{dir}/assets"
    set :slim, :pretty => true
    use SprocketsMiddleware, :root => dir

    
    helpers do
      def root_path
        #"#{env['SCRIPT_NAME']}/"
        "/redis/"
      end
    end

    def initialize
      super
      @r = Redis.new
      @rrd = RReDis.new
    end

    get "/" do
      @metrics = @r.smembers("rrd_metrics_set")
      slim :index
    end

    get "/get" do
      data = {}
      params['aggregations'].split(',').each do |method|
        data[method] = @rrd.get(params['metric'], Time.now-params['timespan'].to_i, Time.now, method)
      end
      JSON.dump(data)
    end

    get "/get_rs" do
      rs = []
mapping = {
  "from" => "to"
}
      params['metric'].split(',').each do |metric|
        name = metric
        name = mapping[metric] if mapping.has_key?(metric)
        data = {key: metric, name: name, data: []}
        d = @rrd.get(metric, Time.now-params['timespan'].to_i, Time.now, "average")
p d
        0.upto(d[0].size-1) do |i|
          data[:data] << {x: d[0][i], y: d[1][i]}
        end
        rs << data
      end
      JSON.dump(rs)
    end
  end

end
