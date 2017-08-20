/**
 * @fileOverview Helps to buffer calls to avoid too frequent calls. 
 */

/**
 * Creates a CallBuffer object.
 * 
 * Once created, use obj.call() to place a buffered call.
 * @param {function} func The function that needs to be called. This function
 *     must have no arguments and return values.
 * @param {number} bufferTimeSec The period of time to buffer a call. A call is
 *     triggered if there is no more calls request within this period.
 * @constructor
 * @returns {CallBuffer}
 */
function CallBuffer(func, bufferTimeSec) {
    var timer = null;
    this.call = function() {
        if (timer) {
            clearTimeout(timer);
        }
        timer = setTimeout(function() {
            func();
        }, bufferTimeSec * 1000);
    };
}
