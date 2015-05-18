/* ========================================================================
 * based on: sliders.js v2.0.2
 * http://goratchet.com/components#sliders
 * ========================================================================
   Adapted from Brad Birdsall's swipe
 * Copyright 2014 Connor Sears
 * Licensed under MIT (https://github.com/twbs/ratchet/blob/master/LICENSE)
 * ======================================================================== */

!(function () {
  'use strict';

  var pageX, pageY, slider, deltaX, deltaY, offsetX,
      lastSlide, startTime, resistance, sliderWidth,
      drawerPosition, isScrolling, scrollableArea,
      startedMoving;

  var getScroll = function () {
    if ('webkitTransform' in slider.style) {
      var translate3d = slider.style.webkitTransform.match(/translate3d\(([^,]*)/);
      var ret = translate3d ? translate3d[1] : 0;
      return parseInt(ret, 10);
    }
  };

  var setDrawerPosition = function (offset) {
    console.log(offset);
    var round = offset ? (deltaX < 0 ? 'ceil' : 'floor') : 'round';
    drawerPosition = Math[round](getScroll() / (scrollableArea / slider.children.length));
    drawerPosition += offset;
    drawerPosition = Math.min(drawerPosition, 0);
    drawerPosition = Math.max(-(slider.children.length - 1), drawerPosition);
  };

  var getDrawerPosition = function() {
    return Math.abs(drawerPosition) > 0 ? 'closed' : 'open';
  }

  var setDrawerPositionOpen = function(e) {
    slider = $('#drawer-container')[0];
    slider.style.webkitTransform = 'translate3d(0,0,0)';
  }
  var setDrawerPositionClosed = function(e) {
    slider = $('#drawer-container')[0];
    slider.style.webkitTransform = 'translate3d(-200px,0,0)';
  }

  var onTouchStart = function (e) {

    slider = $('#drawer-container')[0];

    scrollableArea = 200;
    isScrolling    = undefined;
    sliderWidth    = 200;
    resistance     = 1;
    lastSlide      = 0;
    startTime      = +new Date();
    pageX          = e.touches[0].pageX;
    pageY          = e.touches[0].pageY;
    deltaX         = 0;
    deltaY         = 0;

    slider.style['-webkit-transition-duration'] = 0;
  };

  var onTouchMove = function (e) {
   if (e.touches.length > 1 || !slider) {
      return; // Exit if a pinch || no slider
    }
    // adjust the starting position if we just started to avoid jumpage
    if (!startedMoving) {
      pageX += (e.touches[0].pageX - pageX) - 1;
    }

    deltaX = e.touches[0].pageX - pageX;
    deltaY = e.touches[0].pageY - pageY;
    pageX  = e.touches[0].pageX;
    pageY  = e.touches[0].pageY;

    if (typeof isScrolling === 'undefined' && startedMoving) {
      isScrolling = Math.abs(deltaY) > Math.abs(deltaX);
    }

    if (isScrolling) {
      return;
    }

    offsetX = (deltaX / resistance) + getScroll();

    e.preventDefault();

    resistance = drawerPosition === 0         && deltaX > 0 ? (pageX / sliderWidth) + 1.25 :
                 drawerPosition === lastSlide && deltaX < 0 ? (Math.abs(pageX) / sliderWidth) + 1.25 : 2;

    slider.style.webkitTransform = 'translate3d(' + offsetX + 'px,0,0)';

    // started moving
    startedMoving = true;
  };

  var onTouchEnd = function (e) {
    if (!slider || isScrolling) {
      return;
    }

    // we're done moving
    startedMoving = false;

    setDrawerPosition(
      (+new Date()) - startTime < 1000 && Math.abs(deltaX) > 15 ? (deltaX < 0 ? -1 : 1) : 0
    );

    offsetX = drawerPosition * sliderWidth;

    slider.style['-webkit-transition-duration'] = '.2s';
    slider.style.webkitTransform = 'translate3d(' + offsetX + 'px,0,0)';

    e = new CustomEvent('drawerDidSlide', {
      detail: { sideDrawer: getDrawerPosition() },
      bubbles: true,
      cancelable: true
    });
    slider.parentNode.dispatchEvent(e);
  };


  window.addEventListener('touchstart', onTouchStart);
  window.addEventListener('touchmove', onTouchMove);
  window.addEventListener('touchend', onTouchEnd);
  window.addEventListener('drawerShouldOpen', setDrawerPositionOpen);
  window.addEventListener('drawerShouldClose', setDrawerPositionClosed);
}());