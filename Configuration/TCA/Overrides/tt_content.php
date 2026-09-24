<?php

use TYPO3\CMS\Extbase\Utility\ExtensionUtility;

defined('TYPO3') || exit;

ExtensionUtility::registerPlugin(
    'Find',
    'Find',
    'LLL:EXT:find/Resources/Private/Language/locallang_be.xlf:ce.title',
    'ext-find-ce-wizard',
    'plugins',
    'LLL:EXT:find/Resources/Private/Language/locallang_be.xlf:ce.description'
);
