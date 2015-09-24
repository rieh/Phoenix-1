import QtQuick 2.3
import QtQuick.Layouts 1.1
import QtGraphicalEffects 1.0
import QtQuick.Controls 1.2
import QtQuick.Controls.Styles 1.2
import QtGraphicalEffects 1.0

import vg.phoenix.cache 1.0
import vg.phoenix.themes 1.0
import vg.phoenix.backend 1.0

Rectangle {
    id: boxartGridBackground;
    width: 100; height: 62;

    DropdownMenu { id: dropDownMenu; }

    PhxScrollView {
        id: scrollView;
        anchors { fill: parent; topMargin: headerArea.height; }

        // The default of 20 just isn't fast enough
        __wheelAreaScrollSpeed: 100;

        // Top drop shadow
        Rectangle {
            opacity: gridView.atYBeginning ? 0.0 : 0.3;
            z: 100;
            anchors { top: parent.top; left: parent.left; right: parent.right; }

            height: 25
            gradient: Gradient {
                GradientStop { position: 0.0; color: "black" }
                GradientStop { position: 1.0; color: "transparent" }
            }

            Behavior on opacity { PropertyAnimation { duration: 200 } }
        }

        // Bottom drop shadow
        Rectangle {
            opacity: gridView.atYEnd ? 0.0 : 0.3;
            z: 100;
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right; }

            height: 25;
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent"; }
                GradientStop { position: 1.0; color: "black"; }
            }

            Behavior on opacity { PropertyAnimation { duration: 200; } }
        }

        contentItem: GridView {
            id: gridView;
            anchors {
                top: parent.top; bottom: parent.bottom;
                left: parent.left; right: parent.right;

                topMargin: 16;
                leftMargin: gridView.clampEdges ? ( ( parent.width % cellWidth ) / 2 ) : 0;
                rightMargin: leftMargin;
            }

            // If the grid's width is less than the maxCellWidth, get
            // the grid to scale the size of the grid items, so that the transition looks really
            // seamless.
            cellHeight: clampEdges ? contentArea.contentSlider.value : parent.width;
            cellWidth: cellHeight;

            model: libraryModel;

            // The max height and width of the grid's cells. This can be tweaked
            // to change the default size of the boxart.
            property int maxCellHeight: contentArea.contentSlider.maximumValue;
            property bool clampEdges: parent.width >= maxCellHeight;

            // Define some transition animations
            property Transition transition: Transition { NumberAnimation { properties: "x,y"; duration: 250; } }
            property Transition transitionX: Transition { NumberAnimation { properties: "x"; duration: 250; } }

            // add: transition;
            // addDisplaced: transition;
            // displaced: transition;
            // move: transition;
            // moveDisplaced: transition;
            // populate: transitionX;
            // remove: transition;
            // removeDisplaced: transition;

            // Behavior on contentY { SmoothedAnimation { duration: 250; } }

            // Yes this isn't ideal, but it is a work around for the view resetting back to 0
            // whenever a game is imported.
            /*property real lastY: 0;

            onContentYChanged: {
                if (contentY == 0) {
                    console.log( contentY );
                    if ( Math.round( lastY ) !== 0.0 ) {
                        contentY = lastY;
                    }
                }
                else
                    lastY = contentY;
            }*/

            //clip: true
            boundsBehavior: Flickable.StopAtBounds;

            Component.onCompleted: { populate: transitionX; libraryModel.updateCount(); }

            delegate: Rectangle {
                id: gridItem;
                width: gridView.cellWidth; height: gridView.cellHeight;
                color: "transparent";

                ColumnLayout {
                    spacing: 13;
                    anchors {
                        top: parent.top; bottom: parent.bottom; left: parent.left; right: parent.right;
                        bottomMargin: 24; leftMargin: 24; rightMargin: 24;
                    }

                    Rectangle {
                        id: gridItemImageContainer;
                        color: "transparent";
                        Layout.fillHeight: true;
                        Layout.fillWidth: true;

                        Image {
                            id: gridItemImage;
                            height: parent.height;
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; }
                            visible: true;
                            asynchronous: true;

                            source: imageCacher.cachedUrl == "" ? "missingArtwork.png" : imageCacher.cachedUrl;
                            sourceSize { width: 400; height: 400; }
                            verticalAlignment: Image.AlignBottom;
                            fillMode: Image.PreserveAspectFit;

                            onStatusChanged: {
                                if ( status == Image.Error ) {
                                    console.log( "Error in " + source );
                                    gridItemImage.source = "missingArtwork.png";
                                }

                                // This is not triggered when source is an empty string
                                if ( status == Image.Null ) {
                                    console.log( "No image available for " + title );
                                }
                            }

                            Rectangle {
                                id: imageBackground;
                                anchors {
                                    bottom: parent.bottom;
                                    horizontalCenter: parent.horizontalCenter;
                                    bottomMargin: -7;
                                }
                                z: parent.z - 1;
                                height: parent.paintedHeight + 14;
                                width: parent.paintedWidth + 14;
                                color: PhxTheme.common.boxartNormalBorderColor;

                                gradient: {
                                    return index === gridView.currentIndex ? PhxTheme.common.primaryButtonColor : undefined;
                                }
                            }

                            MouseArea {
                                anchors.fill: parent;
                                onClicked: { gridView.currentIndex = index; }
                                onDoubleClicked: {
                                    if ( root.gameViewObject.coreState === Core.STATEPAUSED ) {
                                        console.log("Shutting down suspended game.");
                                        root.gameViewObject.videoRender.stop();
                                    }

                                    // Prevent user from clicking on anything while the transition occurs
                                    root.disableMouseClicks();

                                    // Don't check the mouse until the transition's done
                                    rootMouseArea.hoverEnabled = false;

                                    rootMouseArea.cursorShape = Qt.BusyCursor;
                                    console.log( coreFilePath + " " + absoluteFilePath );

                                    layoutStackView.get( 0 ).coreGamePair = { "corePath": coreFilePath
                                                                            , "gamePath": absoluteFilePath
                                                                            , "title": title };


                                    layoutStackView.pop();
                                }
                            }

                            ImageCacher {
                                id: imageCacher;
                                imageUrl: artworkUrl;
                                identifier: sha1;

                                Component.onCompleted: cache();
                            }

                            /*Decorations
                            Rectangle {
                                id: imageTopAccent
                                y: gridItemImage.y + ( gridItemImage.height - gridItemImage.paintedHeight );
                                width: gridItemImage.paintedWidth + 2;
                                anchors.horizontalCenter: gridItemImage.horizontalCenter;

                                height: 1;
                                opacity: 0.3;
                                color: "white";
                            }

                            Rectangle {
                                id: imageTopLeft;
                                anchors { top: imageTopAccent.bottom bottom: parent.bottom; }
                                x: ( gridItemImage.width / 2 ) - ( gridItemImage.paintedWidth / 2 ) - 1;

                                width: 1;
                                opacity: 0.10;
                                color: "white";
                            }

                            Rectangle {
                                id: imageTopRight;
                                anchors { top: imageTopAccent.bottom bottom: parent.bottom; }
                                x: ( gridItemImage.width / 2 ) + ( gridItemImage.paintedWidth / 2 );

                                width: 1;
                                opacity: 0.10;
                                color: "white";
                            }*/
                        }
                    }

                    Label {
                        id: titleText;
                        text: title;
                        color: index === gridView.currentIndex ? PhxTheme.common.highlighterFontColor : PhxTheme.common.baseFontColor;
                        Layout.fillWidth: true;
                        elide: Text.ElideRight;
                        font { pixelSize: 10; }
                    }

                    /*Text {
                        id: platformText;
                        anchors {
                            top: titleText.bottom;
                            topMargin: 0;
                        }

                        text: system;
                        color: PhxTheme.common.baseFontColor;
                        Layout.fillWidth: true;
                        elide: Text.ElideRight;
                    }
                    Text {
                        id: absPath;
                        anchors {
                            top: platformText.bottom;

                        }
                        text: sha1; // absolutePath
                        color: PhxTheme.common.baseFontColor;
                        Layout.fillWidth: true;
                        elide: Text.ElideMiddle;
                    }*/
                }
            }
        }
    }
}

