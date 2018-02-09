// Copyright 2011-2018, The Trustees of Indiana University and Northwestern
//   University.  Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed
//   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied. See the License for the
//   specific language governing permissions and limitations under the License.

/**
 * Quality helper class to add functionality to stock MEJS quality plugin
 * @class MEJSQualityHelper
 */
class MEJSQualityHelper {
  constructor() {
    $(document).on('mejs4handleSuccess', this.addQualitySelectorListeners);
  }

  /**
   * Add event listeners to send quality selections to server
   * @function addQualitySelectorListeners
   * @return {void}
   */
  addQualitySelectorListeners() {
    const player = mejs4AvalonPlayer.player;
    const radios = player.qualitiesButton.querySelectorAll(
      'input[type="radio"]'
    );

    for (let i = 0, total = radios.length; i < total; i++) {
      const radio = radios[i];
      radio.addEventListener(
        'change',
        mejs4AvalonPlayer.mejsQualityHelper.sendQualitySelection
      );
    }
  }

  sendQualitySelection(e) {
    $.ajax({
      type: 'POST',
      url: '/media_objects/set_session_quality',
      data: { quality: e.target.value },
      dataType: 'json'
    });
  }
}
