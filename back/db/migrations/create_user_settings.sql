-- user_settings: ユーザーごとの個人設定テーブル
CREATE TABLE IF NOT EXISTS `user_settings` (
  `user_id` bigint unsigned NOT NULL,
  `include_visited_places` tinyint(1) NOT NULL DEFAULT '0',
  `voice_guidance_enabled` tinyint(1) NOT NULL DEFAULT '1',
  `keep_screen_awake` tinyint(1) NOT NULL DEFAULT '1',
  `auto_reroute_enabled` tinyint(1) NOT NULL DEFAULT '1',
  `map_type` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'normal',
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  CONSTRAINT `fk_user_settings_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
