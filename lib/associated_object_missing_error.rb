# -*- encoding : utf-8 -*-
# 関連オブジェクトの存在を前提としているのに見つからなかったとき発生する例外クラス
class AssociatedObjectMissingError < StandardError
end