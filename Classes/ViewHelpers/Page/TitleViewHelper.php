<?php

namespace Subugoe\Find\ViewHelpers\Page;

/*******************************************************************************
 * Copyright notice
 *
 * Copyright 2013 Sven-S. Porst, Göttingen State and University Library
 *                <porst@sub.uni-goettingen.de>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 ******************************************************************************/
use TYPO3\CMS\Core\PageTitle\RecordTitleProvider;
use TYPO3Fluid\Fluid\Core\ViewHelper\AbstractViewHelper;

/**
 * View Helper to set the title of the page.
 *
 * Usage examples are available in Private/Partials/Test.html.
 */
class TitleViewHelper extends AbstractViewHelper
{
    public function __construct(private readonly RecordTitleProvider $recordTitleProvider) {}

    public function initializeArguments(): void
    {
        parent::initializeArguments();
        $this->registerArgument('title', 'string', 'the title to set for the page', false, null);
    }

    public function render(): void
    {
        $title = $this->arguments['title'];
        if ($title === null) {
            $title = $this->renderChildren();
        }

        // $GLOBALS['TSFE'] no longer exists in TYPO3 14, the page title is set via the PageTitle API.
        $this->recordTitleProvider->setTitle((string)$title);
    }
}
