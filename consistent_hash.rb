# コンシステントハッシング
# 分散データベース/キャッシュの保存先を決定するためのハッシュテーブルのアルゴリズム
# modの問題点を解決したアルゴリズム

require 'digest/md5'

class ConsistentHash
  # 仮想ノード数
  # 分散に偏りが出来ないように
  VIRTUAL_NODE_NUM = 100

  # 割り当てるべきノードIDを事前に並べておく
  def initialize(node_id)
    @circle = [] # データの配置
    # ノードIDを追加して円周上に並べる
    # 仮想ノードを追加しておくことで負荷分散の偏りをなくす
    node_id.each do |n|
      add_node(n)
    end
  end

  # MD5でデータIDやノードIDをハッシュ化
  def hash_function(str)
    Digest::MD5.hexdigest(str)
  end

  # ノードの追加
  def add_node(node)
    # ノードIDそれぞれに対して仮想ノードを用意
    VIRTUAL_NODE_NUM.times do |i|
      virtual_node_elm = "_#{i}"
      @circle.push(node_hash: hash_function(node + virtual_node_elm), node_name: node) # ノードを円周上に配置
    end
  end

  # ノードを削除
  def del_node(node)
    VIRTUAL_NODE_NUM.times do |i|
    virtual_node_elm = "_#{i}"
    @circle.delete(node_hash: hash_function(node + virtual_node_elm), node_name: node) # 円周上からノードを削除
    end
  end

  # ノードIDとデータIDをハッシュ化した際の辞書順で並べる
  # データIDより後に来る最初のノードIDにデータIDを割当
  def sort_and_assign_node(key)
    if @circle.empty? # ノードIDがなければnil
      return nil
    else
      # ブロックで使うにはsortは致命的な速度低下をおこすらしい
      # sort_byの方がはるかに早いらしいので今回はsort_by
      @circle = @circle.sort_by { |n| n[:node_hash] } # ノードIDをハッシュ化した際の辞書順に並び替える
      data_id_hash = hash_function(key) # data_idをハッシュ化
      nearest_node = []
      @circle.each do |node|
        if node[:node_hash] == data_id_hash # データIDのハッシュと同じノードがあれば
          nearest_node = node
          break
        elsif node[:node_hash] > data_id_hash # データIDより大きいハッシュ値を持つノードを見つけたら
          nearest_node = node
          break
        else # 全てなければハッシュ値が最小のノード
          nearest_node = @circle.first
        end
      end
      # 割り当てたノードが見やすくなるようにノード名(id)を返す
      nearest_node[:node_name]
    end
  end

  # どこに割り当てているかを表示
  def print_data(data)
    result = {} # 結果のハッシュ
    data.each do |d|
      node = sort_and_assign_node(d) # 割り当てられたノードIDを代入
      result[node] = [] unless result[node] # 最初はresult[node]が無いので作っておく
      result[node].push(d) # 結果を追加していく
    end
    # 整形して表示
    result.each do |node_id, data_id|
      puts "#{node_id}: #{data_id.join(',')}"
    end
  end
end

data_id = ConsistentHash.new(['n1', 'n2', 'n3', 'n4'])

puts "ノードID: n1, n2, n3, n4"
data_id.print_data('A'..'Z')
data_id.del_node('n4') # ノードを一つ削除して割り当ての様子を見る
puts ""
puts "ノードID: n1, n2, n3"
data_id.print_data('A'..'Z')
data_id.add_node('n5') # もう一度別のノードを追加して割り当ての様子を確認
puts ""
puts "ノードID: n1, n2, n3, n5"
data_id.print_data('A'..'Z')
