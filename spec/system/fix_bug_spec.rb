require 'rails_helper'

RSpec.describe 'バグだらけのアプリ', type: :system do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:post) { create(:post, user: user) }
  let(:other_post) { create(:post, user: other_user) }

  describe 'トップページからの導線の確認' do
    describe 'トップページから始めようボタンにアクセスする' do
      context 'ログインしていない場合' do
        it '新規会員登録へ遷移できること' do
          visit root_path
          click_on('はじめよう')
          Capybara.assert_current_path("/signup", ignore_query: true)
          expect(current_path).to eq('/signup'), '新規会員登録へ遷移できません'
        end
      end

      context 'ログインしている場合' do
        before do
          login_as_user(user)
        end

        it '投稿一覧へ遷移できること' do
          visit root_path
          click_on('はじめよう')
          Capybara.assert_current_path("/posts", ignore_query: true)
          expect(current_path).to eq('/posts'), '投稿一覧画面へ遷移できません'
        end
      end
    end
  end

  describe 'ログアウト機能' do
    describe 'ログイン後にヘッダーからログアウトリンクをクリックする' do
      before do
        login_as_user(user)
      end

      it 'ログアウトできること' do
        find('#header-profile').click
        click_on('ログアウト')
        Capybara.assert_current_path("/", ignore_query: true)
        expect(current_path).to eq root_path
        expect(page).to have_content('ログアウトしました'), 'フラッシュメッセージ「ログアウトしました」が表示されていません'
      end
    end
  end

  describe '投稿作成機能' do
    describe 'ログイン後に投稿が作成できること' do
      before do
        login_as_user(user)
      end

      it '投稿が作成できること' do
        visit new_post_path
        Capybara.assert_current_path("/posts/new", ignore_query: true)
        fill_in 'タイトルを入力してください', with: 'テストタイトル'
        fill_in '好きに書いてね', with: 'テスト本文'
        expect {
          click_button '投稿する'
          Capybara.assert_current_path("/posts", ignore_query: true)
        }.to change(Post, :count).by(1)
      end
    end
  end

  describe '投稿詳細閲覧機能' do
    describe '投稿のタイトル・タグ・本文を入力が表示されること' do
      before do
        login_as_user(user)
      end

      context 'ログインユーザーが作成した投稿の詳細ページにアクセスする' do
        it '作成した投稿のタイトル・タグ・本文が表示されること' do
          visit post_path(post)
          Capybara.assert_current_path("/posts/#{post.id}", ignore_query: true)
          expect(page).to have_content(post.title), '投稿一覧画面に投稿のタイトルが表示されていません'
          expect(page).to have_content(user.nickname), '投稿一覧画面に投稿者のニックネームが表示されていません'
          expect(page).to have_content(post.content), '投稿一覧画面に投稿の本文が表示されていません'
        end
      end
      context '他人が作成した投稿の詳細ページにアクセスする' do
        it '他人が作成した投稿のタイトル・タグ・本文が表示されること' do
          visit post_path(other_post)
          Capybara.assert_current_path("/posts/#{other_post.id}", ignore_query: true)
          expect(page).to have_content(other_post.title), '投稿一覧画面に投稿のタイトルが表示されていません'
          expect(page).to have_content(other_user.nickname), '投稿一覧画面に投稿者のニックネームが表示されていません'
          expect(page).to have_content(other_post.content), '投稿一覧画面に投稿の本文が表示されていません'
        end
      end
    end
  end

  describe '投稿の削除機能' do
    describe '自分が作成した投稿の詳細ページから削除ボタンをクリックする' do
      before do
        login_as_user(user)
      end

      it '投稿が削除できること' do
        visit post_path(post)
        Capybara.assert_current_path("/posts/#{post.id}", ignore_query: true)
        find('#post-detail-menu').click
        page.accept_confirm { find("#button-delete-#{post.id}").click }

        Capybara.assert_current_path("/posts", ignore_query: true)
        expect(current_path).to eq('/posts'), '投稿削除後に、投稿の一覧ページに遷移していません'
        expect(page).to have_content('削除しました'), 'フラッシュメッセージ「削除しました」が表示されていません'
      end
    end
  end

  describe '編集・更新機能' do
    before do
      login_as_user(user)
    end

    describe '自分が作成した投稿の詳細ページから更新ボタンをクリックする' do
      it '投稿が更新できること' do
        visit edit_post_path(post)
        fill_in 'タイトルを入力してください', with: '新しいタイトル'
        fill_in '好きに書いてね', with: '新しい本文'
        click_button '更新する'
        Capybara.assert_current_path("/posts", ignore_query: true)
        visit post_path(post)
        expect(page).to have_content('新しいタイトル'), '投稿一覧画面に投稿のタイトルが表示されていません'
      end
    end

    describe '他人が作成した投稿の編集ページへアクセスしようとする' do
      it '他人が作成した投稿の編集ページへアクセスできないこと' do
        visit edit_post_path(other_post)
        expect(page).to have_content('ActiveRecord::RecordNotFound')
      end
    end
  end
end
