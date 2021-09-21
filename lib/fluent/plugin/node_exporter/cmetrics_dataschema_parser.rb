#
# Copyright 2021- Kentaro Hayashi
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "cmetrics"
require "fluent/plugin/input"

module Fluent
  module Plugin
    module NodeExporter
      class CMetricsDataSchemaParser
        def parse(metrics)
          data = []
          begin
            metrics.each do |metric|
              next if metric["values"].empty?
              data << to_readable_hash(metric)
            end
          rescue => e
            raise Fluent::ParserError.new(e.message)
          end
          data.flatten
        end

        # Parsed CMetrics Data Schema Format
        # {
        #  "name" => metrics name
        #  "time" => Fluent::EventTime
        #  "labels" => {"key" => value, ...}
        #  "value" => ...
        # }
        #
        # "labels" field is optional. It is available when {"meta"=>"label_dictionary"...} and
        # "labels" in "values" => [{"ts"=>..., "labels"=>[...]}]..
        #
        def to_readable_hash(metrics)
          opts = metrics["meta"]["opts"]

          metric_name = if opts["ss"].size.zero?
                          "#{opts['ns']}_#{opts['name']}"
                        else
                          "#{opts['ns']}_#{opts['ss']}_#{opts['name']}"
                        end
          cmetrics = []
          labels = []
          unless metrics["meta"]["labels"].empty?
            metrics["meta"]["labels"].each do |v|
              labels << metrics["meta"]["label_dictionary"][v]
            end
          end
          metrics["values"].each do |entry|
            cmetric = {
              "name" => metric_name,
              "value" => entry["value"],
              "desc" => opts["desc"],
              "ts" => entry["ts"]
            }
            unless metrics["meta"]["labels"].empty?
              params = {}
              entry["labels"].each_with_index do |v, index|
                label = labels[index]
                params[label] = metrics["meta"]["label_dictionary"][v]
              end
              cmetric["labels"] = params
            end
            cmetrics << cmetric
          end
          cmetrics
        end
      end
    end
  end
end
