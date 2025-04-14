# README
## セットアップ
```
docker compose up
```

## 動作確認
```
docker compose exec web bundle exec rspec
```

## 行うこと
RSpecのテストが全て通るようにアプリケーションの修正を行ってください。

※テストコードは変更しないでください。
テストコードにデバッグツール用のブレークポイントを設置することは構いませんが、テスト実行時にはもとの状態に戻してください。

## デバッグツールの使用方法
このアプリケーションにはgem 'debug'が含まれています。デバッグツールを使用するには、以下の手順に従ってください。
また、Docker環境で実行しやすくなるため下記の設定がconfig/application.rbに追加されています。
```ruby
if defined?(Rails::Server) && Rails.env.development?
  require "debug/open_nonstop"
end
```

### デバッグツールの使用方法
#### 1. docker compose upでアプリケーションを起動します。
docker compose upを実行すると内部で下記のコマンドが実行され、gemのインストールやデータベースの準備、サーバーの起動が行われます。

- yarn install
- bundle install
- bundle exec rails db:prepare
- rm -f tmp/pids/server.pid
- bin/dev

#### 2. docker compose exec web bundle exec rdbg -aを実行してデバッグセッションを開始します。
以下のようなメッセージが表示されます。
(rdbg:remote)の箇所でrubyやrailsのコードの実行、debug gemのコマンドを実行することができます。

```
>>>docker compose exec web bundle exec rdbg -a
DEBUGGER (client): Connected. PID:1310, $0:bin/rails

# No sourcefile available for /usr/local/bundle/gems/puma-6.4.3/lib/puma/single.rb
=>#0    [C] Thread#join at /usr/local/bundle/gems/puma-6.4.3/lib/puma/single.rb:63
  #1    Puma::Single#run at /usr/local/bundle/gems/puma-6.4.3/lib/puma/single.rb:63
  # and 20 frames (use `bt' command for all frames)

Stop by SIGURG
(rdbg:remote)
```
#### 4. デバッグを行いたい箇所にブレークポイント(binding.break)を設置してください。

例
```
  def index
    binding.break
    if params[:tag].present? && params[:tag].is_a?(String)
      @posts = Post.tagged_with(params[:tag].strip).order(created_at: :desc)
    else
      @posts = Post.all.order(created_at: :desc)
    end
  end
```

#### 5. ブレークポイントが設置された箇所が動作させてください
4の例では`localhost:3000/posts`にアクセスすることでindexメソッドが動作します

ブレークポイントを設置したうえで該当部分の処理を行うと、ブラウザの画面がリロード中の状態で止まります。

`docker compose exec web bundle exec rdbg -a`を実行したターミナルのタブを確認すると、デバッグセッションが開始され下記のようなメッセージが表示されます。
※何も表示されない場合は(rdbg:remote)にcontinueと入力してみてください。

```
>>>docker compose exec web bundle exec rdbg -a
DEBUGGER (client): Connected. PID:50, $0:bin/rails

[1, 10] in /myapp/app/controllers/posts_controller.rb
     1| class PostsController < ApplicationController
     2|   skip_before_action :require_login, only: %i[index show]
     3|   def index
=>   4|     binding.break
     5|     if params[:tag].present? && params[:tag].is_a?(String)
     6|       @posts = Post.tagged_with(params[:tag].strip).order(created_at: :desc)
     7|     else
     8|       @posts = Post.all.order(created_at: :desc)
     9|     end
    10|   end
=>#0    PostsController#index at /myapp/app/controllers/posts_controller.rb:4
  #1    ActionController::BasicImplicitRender#send_action(method="index", args=[]) at /usr/local/bundle/gems/actionpack-7.2.1/lib/action_controller/metal/basic_implicit_render.rb:8
  # and 77 frames (use `bt' command for all frames)
```

#### 6. デバッグのためrubyやrailsのコードを実行します。

`=>`が記載されている箇所でプログラムの処理が中断されている状態です。
この箇所から上部に記載されている変数の値の確認や、下部に記載されているこれから実行するコードを実行して実行結果を確認することが出来ます。

```
Stop by SIGURG
(rdbg:remote) continue    # command
[1, 10] in /myapp/app/controllers/posts_controller.rb
     1| class PostsController < ApplicationController
     2|   skip_before_action :require_login, only: %i[index show]
     3|   def index
=>   4|     binding.break
     5|     if params[:tag].present? && params[:tag].is_a?(String)
     6|       @posts = Post.tagged_with(params[:tag].strip).order(created_at: :desc)
     7|     else
     8|       @posts = Post.all.order(created_at: :desc)
     9|     end
    10|   end
=>#0    PostsController#index at /myapp/app/controllers/posts_controller.rb:4
  #1    ActionController::BasicImplicitRender#send_action(method="index", args=[]) at /usr/local/bundle/gems/actionpack-7.2.1/lib/action_controller/metal/basic_implicit_render.rb:8
  # and 77 frames (use `bt' command for all frames)
```

例えば、Post.allを実行すると、Postモデルの全てのレコードが表示されます。
また、`params[:tag].present? && params[:tag].is_a?(String)`と実行するとif文の分岐がtrueなのかfalseなのかを確認することが出来ます。

```
(ruby:remote) Post.all
[#<Post:0x00007f65f20c1c28
  id: 1,
  title: "ヴィヨンの妻",
  content: "#### 魅力\nこうぞくしゅしょうおんとう。避けるしょうがっこう春休み。雑音しょうじょうそんざい。う...",
  created_at: "2025-04-11 18:52:03.751371000 +0900",
  updated_at: "2025-04-11 18:52:03.751371000 +0900",
  user_id: 1,
  tag_list: nil>,
 #<Post:0x00007f65f053f8d8
  id: 2,
  title: "一握の砂",
  content: "## 魔術\n電話つうやく老齢。迷子とりあえず開閉。たくす普及きょだい。すいせんほうしゅうたいりく。へ...",
  ...
  ```

#### 7. デバッグセッションを終了する
デバッグセッションを終了するには、`quit`と入力してください。もしくはCtrl + Dを押してください。

```
(rdbg:remote) quit    # command
Really quit? [Y/n] y
disconnected (quit)
```

※ デバッグで確認したい値が確認出来たらコード上からブレークポイントを削除しておくと意図しない処理の中断を防ぐことが出来ます。

## テスト実行時のスクリーンショットの確認方法
システムスペックのテスト失敗時にはテストが失敗した箇所のスクリーンショットが添付されていることがあります。

```
Failures:

  1) バグだらけのアプリ エラー1: トップページからのリンク トップページから始めようボタンにアクセスする ログインしていない場合 新規会員登録へ遷移できること
     Failure/Error: Capybara.assert_current_path("/signup", ignore_query: true)

     Capybara::ExpectationNotMet:
       expected "/signup_path" to equal "/signup"

     [Screenshot Image]: /myapp/tmp/capybara/failures_r_spec_example_groups_nested_nested1_nested_nested_-_849.png


     # /usr/local/bundle/gems/capybara-3.40.0/lib/capybara/session/matchers.rb:24:in `block in assert_current_path'
     # /usr/local/bundle/gems/capybara-3.40.0/lib/capybara/session/matchers.rb:75:in `block in _verify_current_path'
     # /usr/local/bundle/gems/capybara-3.40.0/lib/capybara/node/base.rb:84:in `synchronize'
     # /usr/local/bundle/gems/capybara-3.40.0/lib/capybara/session/matchers.rb:74:in `_verify_current_path'
     # /usr/local/bundle/gems/capybara-3.40.0/lib/capybara/session/matchers.rb:23:in `assert_current_path'
     # /usr/local/bundle/gems/capybara-3.40.0/lib/capybara/dsl.rb:52:in `call'
     # /usr/local/bundle/gems/capybara-3.40.0/lib/capybara/dsl.rb:52:in `assert_current_path'
     # ./spec/system/fix_bug_spec.rb:15:in `block (5 levels) in <top (required)>'
```

下記のような部分がスクリーンショットの保存先を示しています。

```
[Screenshot Image]: /myapp/tmp/capybara/failures_r_spec_example_groups_nested_nested1_nested_nested_-_849.png
```

### スクリーンショットファイルの開き方
`/myapp/`の部分はDockerコンテナの中のパスを示しています。
PC上で確認するためにはtmpから先のファイルを探して、ファイルを開く必要があります。

codeコマンドが設定されていれば下記のようにVSCode上から開くことが出来ます
```
code tmp/capybara/failures_r_spec_example_groups_nested_nested1_nested_nested_-_849.png
```

Macの場合は下記のようにopenコマンドを実行することで、Finder上から開くことも出来ます
```
open tmp/capybara/failures_r_spec_example_groups_nested_nested1_nested_nested_-_849.png
```

スクリーンショットはテストが通らない時の原因を探るのに役立ちます。
画面から何が起こっているのかを推測してバグの調査に役立ててください。
[![Image from Gyazo](https://t.gyazo.com/teams/startup-technology/292150184d82cc2c7d778152ae81db43.png)](https://startup-technology.gyazo.com/292150184d82cc2c7d778152ae81db43)

## テストコードを部分的に実行する方法
RSpecのテストコードはファイル名や行番号を指定することで、特定のテストコードだけを実行することが出来ます。
[![Image from Gyazo](https://t.gyazo.com/teams/startup-technology/c7aef90e4bf1f3a144ad0c3734d136b3.png)](https://startup-technology.gyazo.com/c7aef90e4bf1f3a144ad0c3734d136b3)

例えば下記の箇所のテストを確認したい場合は
```rspec ./spec/system/fix_bug_spec.rb:12 # バグだらけのアプリ エラー1: トップページからのリンク トップページから始めようボタンにアクセスする ログインしていない場合 新規会員登録へ遷移できること
```

下記のように実行することで、特定のテストコードだけを実行することが出来ます。
```
docker compose exec web bundle exec rspec spec/system/fix_bug_spec.rb:12
```

実行結果
```
>>>docker compose exec web bundle exec rspec spec/system/fix_bug_spec.rb:12
Run options: include {:locations=>{"./spec/system/fix_bug_spec.rb"=>[12]}}
F

Failures:

  1) バグだらけのアプリ エラー1: トップページからのリンク トップページから始めようボタンにアクセスする ログインしていない場合 新規会員登録へ遷移できること
     Failure/Error: Capybara.assert_current_path("/signup", ignore_query: true)

     Capybara::ExpectationNotMet:
       expected "/signup_path" to equal "/signup"

     [Screenshot Image]: /myapp/tmp/capybara/failures_r_spec_example_groups_nested_nested1_nested_nested_-_137.png


     # /usr/local/bundle/gems/capybara-3.40.0/lib/capybara/session/matchers.rb:24:in `block in assert_current_path'
     # /usr/local/bundle/gems/capybara-3.40.0/lib/capybara/session/matchers.rb:75:in `block in _verify_current_path'
     # /usr/local/bundle/gems/capybara-3.40.0/lib/capybara/node/base.rb:84:in `synchronize'
     # /usr/local/bundle/gems/capybara-3.40.0/lib/capybara/session/matchers.rb:74:in `_verify_current_path'
     # /usr/local/bundle/gems/capybara-3.40.0/lib/capybara/session/matchers.rb:23:in `assert_current_path'
     # /usr/local/bundle/gems/capybara-3.40.0/lib/capybara/dsl.rb:52:in `call'
     # /usr/local/bundle/gems/capybara-3.40.0/lib/capybara/dsl.rb:52:in `assert_current_path'
     # ./spec/system/fix_bug_spec.rb:15:in `block (5 levels) in <top (required)>'

Finished in 3.01 seconds (files took 0.70343 seconds to load)
1 example, 1 failure

Failed examples:

rspec ./spec/system/fix_bug_spec.rb:12 # バグだらけのアプリ エラー1: トップページからのリンク トップページから始めようボタンにアクセスする ログインしていない場合 新規会員登録へ遷移できること

exit status 1
```

このように特定のテストコードだけを実行することで、全体のテストを実行する分の時間を短縮することが出来ます。