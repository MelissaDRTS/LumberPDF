/**
 * Created by Andrew McGuiness on 9/26/2019.
 */

public with sharing class ParsingHelper {
    /**
     * Parse a date out of a string assuming the incoming String is formatted as
     * MM/DD/YYYY
     *
     * @param originalDate String date in the format: MM/DD/YYYY
     *
     * @return  Converted Salesforce Date object.
     */
    public static Date parseDateLumberToSF(String originalDate) {
        Integer year = Integer.valueOf(originalDate.substring(6));
        Integer month = Integer.valueOf(originalDate.substring(0, 2));
        Integer day = Integer.valueOf(originalDate.substring(3, 5));

        return Date.valueOf(year + '-' + month + '-' + day);
    }

    public static String parseDateSFToLumber(Date originalDate){
        String year = '' + originalDate.year();
        String month = '' + originalDate.month();
        if(month.length() < 2){
            month = '0' + month;
        }

        String day = '' + originalDate.day();
        if(day.length() < 2){
            day = '0' + day;
        }

        return month + '/' + day + '/' + year;
    }

    /**
     * Parse a Time out of a string assuming the incoming String is formatted as
     * HH:MM:SS using 24 hour clock.
     *
     * @param originalTime  String Time in the format: HH:MM:SS
     *
     * @return  Converted Salesforce Time object.
     */
    public static Time parseTime(String originalTime){
        Integer hours = Integer.valueOf(originalTime.substring(0, 2));
        Integer minutes = Integer.valueOf(originalTime.substring(3, 5));
        Integer seconds = Integer.valueOf(originalTime.substring(6, 8));

        return Time.newInstance( hours, minutes, seconds, 0);
    }

    /**
     * Parse the Document Type from a ContentVersion's Title.  This assume the Title is in
     * the following format: WD_userEnteredTitle_DocumentType_ServiceRequestNum.extension.
     *
     * @param title Title of the ContentVersion to parse.
     *
     * @return  The Document Type parsed from the title.
     */
    public static String parseDocumentType(String title) {
        Integer lastUnderscore = title.lastIndexOf('_');
        Integer secondToLastUnderscore = title.substring(0, lastUnderscore).lastIndexOf('_');

        return title.substring(secondToLastUnderscore + 1, lastUnderscore);
    }

    /**
     * Parse the Service number from a ContentVersion's Title.  This assume the Title is in
     * the following format: WD_userEnteredTitle_DocumentType_ServiceRequestNum.extension.
     *
     * @param title Title of the ContentVersion to parse.
     *
     * @return  The ServiceNumber parsed from the title.
     */
    public static String parseServiceNumber(String title) {
        Integer lastUnderscore = title.lastIndexOf('_');
        Integer lastPeriod = title.lastIndexOf('.');
        if (lastPeriod == -1) {
            return title.substring(lastUnderscore + 1);
        } else {
            return title.substring(lastUnderscore + 1, lastPeriod);
        }
    }
}