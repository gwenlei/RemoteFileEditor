/**
 * @fileOverview Some utility functions.
 */

/**
 * Gets parameter value from the current url.
 * @param {type} name
 * @returns {Array|gup.results}
 */
function gup(name) {
    name = name.replace(/[\[]/, '\\\[').replace(/[\]]/, '\\\]');
    var regexS = '[\\?&]' + name + '=([^&#]*)';
    var regex = new RegExp(regexS);
    var results = regex.exec(location.href);
    if (results === null) {
        return null;
    } else {
        return results[1];
    }
}



