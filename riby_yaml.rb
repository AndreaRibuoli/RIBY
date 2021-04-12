#! /QOpenSys/pkgs/bin/ruby
require 'yaml'

SQL_ATTR_VALUES = { :SQL_ATTR_TXN_ISOLATION => {
                      :SQL_TXN_NO_COMMIT                      => 0,
                      :SQL_TXN_READ_UNCOMMITTED_MASK          => 1,
                      :SQL_TXN_READ_COMMITTED_MASK            => 2,
                      :SQL_TXN_REPEATABLE_READ_MASK           => 4,
                      :SQL_TXN_SERIALIZABLE_MASK              => 8 },
                    :SQL_ATTR_CONCURRENT_ACCESS_RESOLUTION => {
                      :SQL_CONCURRENT_ACCESS_RESOLUTION_UNSET => 0,
                      :SQL_USE_CURRENTLY_COMMITTED            => 1,
                      :SQL_WAIT_FOR_OUTCOME                   => 2,
                      :SQL_SKIP_LOCKED_DATA                   => 3 } }

File.open("sqlattrvals.yaml", "w") {|f| YAML.dump(SQL_ATTR_VALUES, f)}
